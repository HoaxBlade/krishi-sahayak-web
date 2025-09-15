#!/usr/bin/env python3
"""
Production ML Server for Krishi Sahayak
Optimized for Kubernetes deployment with proper logging and monitoring
"""

import os
import sys
import time
import logging
import threading
import collections
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory
from werkzeug.exceptions import RequestEntityTooLarge
import psutil
import numpy as np
from PIL import Image
import tensorflow as tf # type: ignore
import io
import base64
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Rate limiting configuration
RATE_LIMIT_REQUESTS = int(os.getenv('RATE_LIMIT_REQUESTS', '100'))  # requests per window
RATE_LIMIT_WINDOW = int(os.getenv('RATE_LIMIT_WINDOW', '3600'))  # 1 hour in seconds
MAX_FILE_SIZE = int(os.getenv('MAX_FILE_SIZE', '10485760'))  # 10MB

# Global variables for rate limiting and monitoring
user_requests = collections.defaultdict(list)
rate_limit_lock = threading.Lock()
request_queue = collections.deque()
queue_lock = threading.Lock()
processing_lock = threading.Lock()
start_time = time.time()

# System monitoring
class SystemMonitor:
    @staticmethod
    def get_memory_usage():
        """Get current memory usage percentage"""
        try:
            memory = psutil.virtual_memory()
            return {
                'used_percent': memory.percent,
                'used_mb': memory.used / 1024 / 1024,
                'total_mb': memory.total / 1024 / 1024
            }
        except Exception as e:
            logger.error(f"Error getting memory usage: {e}")
            return {'used_percent': 0, 'used_mb': 0, 'total_mb': 0}
    
    @staticmethod
    def get_cpu_usage():
        """Get current CPU usage percentage"""
        try:
            return psutil.cpu_percent(interval=1)
        except Exception as e:
            logger.error(f"Error getting CPU usage: {e}")
            return 0
    
    @staticmethod
    def is_system_healthy():
        """Check if system has enough resources"""
        memory = SystemMonitor.get_memory_usage()
        cpu = SystemMonitor.get_cpu_usage()
        
        # System is healthy if memory < 90% and CPU < 80%
        return memory['used_percent'] < 90 and cpu < 80

# Rate limiter
class RateLimiter:
    def __init__(self):
        self.requests = collections.defaultdict(list)
        self.lock = threading.Lock()
    
    def is_allowed(self, user_id):
        """Check if user is within rate limits"""
        with self.lock:
            now = time.time()
            # Clean old requests
            self.requests[user_id] = [
                req_time for req_time in self.requests[user_id]
                if now - req_time < RATE_LIMIT_WINDOW
            ]
            
            # Check if under limit
            if len(self.requests[user_id]) < RATE_LIMIT_REQUESTS:
                self.requests[user_id].append(now)
                return True
            return False
    
    def get_remaining_requests(self, user_id):
        """Get remaining requests for user"""
        with self.lock:
            now = time.time()
            self.requests[user_id] = [
                req_time for req_time in self.requests[user_id]
                if now - req_time < RATE_LIMIT_WINDOW
            ]
            return max(0, RATE_LIMIT_REQUESTS - len(self.requests[user_id]))

# Initialize Flask app
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Initialize components
rate_limiter = RateLimiter()
system_monitor = SystemMonitor()

# Load ML model (Keras .h5 preferred) and warm-up
model = None  # global model instance

def load_model():
    """Load the ML model from common paths and run warm-up inference."""
    global model
    model_paths = [
        "saved_models/best_modelV1.h5",
        "notebooks/model/best_model.h5",
        "notebooks/model/mobilenetv2_model.h5",
        "model/best_model.h5",
        "model/mobilenetv2_model.h5"
    ]
    for model_path in model_paths:
        if os.path.exists(model_path):
            try:
                logger.info(f"Attempting to load model from: {model_path}")
                model = tf.keras.models.load_model(model_path)
                # Warm-up for lower p95 latency
                _ = model.predict(np.zeros((1, 224, 224, 3), dtype=np.float32))
                logger.info(f"✅ Model loaded and warmed from {model_path}")
                return True
            except Exception as e:
                logger.error(f"Error loading model from {model_path}: {e}")
                model = None
                continue
    logger.error("❌ No valid model file found in known paths")
    return False

# Load model on startup
model_loaded = load_model()

@app.errorhandler(RequestEntityTooLarge)
def handle_file_too_large(e):
    return jsonify({
        'error': 'File too large',
        'message': f'Maximum file size is {MAX_FILE_SIZE / 1024 / 1024:.1f}MB',
        'status': 'error'
    }), 413

@app.route('/health', methods=['GET'])
def health_check():
    """Enhanced health check endpoint"""
    try:
        memory = system_monitor.get_memory_usage()
        cpu = system_monitor.get_cpu_usage()
        uptime = time.time() - start_time
        
        return jsonify({
            'status': 'healthy' if model_loaded and system_monitor.is_system_healthy() else 'unhealthy',
            'timestamp': datetime.utcnow().isoformat(),
            'uptime_seconds': uptime,
            'model_loaded': model_loaded,
            'system': {
                'memory_usage_percent': memory['used_percent'],
                'memory_used_mb': memory['used_mb'],
                'memory_total_mb': memory['total_mb'],
                'cpu_usage_percent': cpu
            },
            'rate_limiting': {
                'max_requests_per_hour': RATE_LIMIT_REQUESTS,
                'window_seconds': RATE_LIMIT_WINDOW
            }
        })
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/status', methods=['GET'])
def detailed_status():
    """Detailed server status for monitoring"""
    try:
        memory = system_monitor.get_memory_usage()
        cpu = system_monitor.get_cpu_usage()
        uptime = time.time() - start_time
        
        # Get queue status
        with queue_lock:
            queue_size = len(request_queue)
        
        # Get active users
        with rate_limit_lock:
            active_users = len(user_requests)
        
        return jsonify({
            'server': {
                'status': 'running',
                'uptime_seconds': uptime,
                'uptime_human': f"{int(uptime // 3600)}h {int((uptime % 3600) // 60)}m {int(uptime % 60)}s",
                'start_time': datetime.fromtimestamp(start_time).isoformat()
            },
            'model': {
                'loaded': model_loaded,
                'status': 'ready' if model_loaded else 'error'
            },
            'system': {
                'memory': memory,
                'cpu_percent': cpu,
                'healthy': system_monitor.is_system_healthy()
            },
            'rate_limiting': {
                'max_requests_per_hour': RATE_LIMIT_REQUESTS,
                'window_seconds': RATE_LIMIT_WINDOW,
                'active_users': active_users
            },
            'queue': {
                'size': queue_size,
                'processing': 'idle'
            }
        })
    except Exception as e:
        logger.error(f"Status check error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/analyze_crop', methods=['POST'])
def analyze_crop():
    """Analyze crop image for disease detection"""
    start_time_req = time.time()
    
    try:
        # Check system health
        if not system_monitor.is_system_healthy():
            return jsonify({
                'error': 'Server overloaded',
                'message': 'Server is currently under heavy load. Please try again later.',
                'status': 'error'
            }), 503
        
        # Get user ID from headers or IP
        user_id = request.headers.get('X-User-ID', request.remote_addr)
        
        # Check rate limiting
        if not rate_limiter.is_allowed(user_id):
            remaining = rate_limiter.get_remaining_requests(user_id)
            return jsonify({
                'error': 'Rate limit exceeded',
                'message': f'Too many requests. Try again in {RATE_LIMIT_WINDOW // 60} minutes.',
                'remaining_requests': remaining,
                'status': 'error'
            }), 429
        
        # Get image data (handle both file upload and base64)
        image_data = None
        
        # Check if image is sent as file upload
        if 'image' in request.files:
            image_file = request.files['image']
            if image_file.filename != '':
                try:
                    image = Image.open(image_file.stream)
                    image_data = image
                except Exception as e:
                    logger.error(f"File upload processing error: {e}")
                    return jsonify({
                        'error': 'Invalid image file',
                        'message': 'Could not process the uploaded image file',
                        'status': 'error'
                    }), 400
        
        # Check if image is sent as base64 in JSON
        elif request.is_json and 'image' in request.get_json():
            try:
                base64_data = request.get_json()['image']
                # Remove data URL prefix if present
                if base64_data.startswith('data:image'):
                    base64_data = base64_data.split(',')[1]
                
                # Decode base64 image
                image_bytes = base64.b64decode(base64_data)
                image = Image.open(io.BytesIO(image_bytes))
                image_data = image
                logger.info(f"Base64 image decoded successfully: {image.size}")
            except Exception as e:
                logger.error(f"Base64 processing error: {e}")
                return jsonify({
                    'error': 'Invalid base64 image',
                    'message': 'Could not process the base64 image data',
                    'status': 'error'
                }), 400
        
        # If no image data found
        if image_data is None:
            return jsonify({
                'error': 'No image provided',
                'message': 'Please provide an image file or base64 image data',
                'status': 'error'
            }), 400
        
        # Process image
        try:
            image = image_data.convert('RGB')
            image = image.resize((224, 224))  # Resize for model input
            
            # Convert to numpy array
            img_array = np.array(image) / 255.0
            img_array = np.expand_dims(img_array, axis=0)
            logger.info(f"Image processed successfully: {img_array.shape}")
            
        except Exception as e:
            logger.error(f"Image processing error: {e}")
            return jsonify({
                'error': 'Invalid image',
                'message': 'Could not process the provided image',
                'status': 'error'
            }), 400
        
        # Real ML prediction
        try:
            preds = model.predict(img_array)[0]  # shape (17,)
            all_predictions = [float(p) for p in preds.tolist()]
            prediction_class = int(np.argmax(preds))
            confidence = float(np.max(preds))

            disease_names = [
                'Rice Blast', 'Rice Brown Spot', 'Rice Bacterial Blight', 'Rice Sheath Blight',
                'Wheat Rust', 'Wheat Scab', 'Wheat Powdery Mildew', 'Wheat Septoria',
                'Corn Smut', 'Corn Rust', 'Corn Leaf Blight', 'Corn Gray Leaf Spot',
                'Sugarcane Mosaic', 'Sugarcane Rust', 'Sugarcane Red Rot', 'Sugarcane Smut',
                'Healthy'
            ]

            predicted_disease = disease_names[prediction_class]
            health_status = 'healthy' if prediction_class == 16 else 'diseased'
        
        except Exception as e:
            logger.error(f"ML prediction error: {e}")
            return jsonify({
                'error': 'Prediction failed',
                'message': 'Could not analyze the image',
                'status': 'error'
            }), 500
        
        # Calculate processing time
        processing_time = time.time() - start_time_req
        
        # Log successful analysis
        logger.info(f"Crop analysis completed for user {user_id} in {processing_time:.2f}s")
        
        # Return results
        return jsonify({
            'status': 'success',
            'prediction_class': int(prediction_class),
            'confidence': confidence,
            'all_predictions': all_predictions,
            'predicted_disease': predicted_disease,
            'health_status': health_status,
            'processing_time_seconds': processing_time,
            'system_info': {
                'memory_usage_percent': system_monitor.get_memory_usage()['used_percent'],
                'cpu_usage_percent': system_monitor.get_cpu_usage()
            }
        })
        
    except Exception as e:
        logger.error(f"Unexpected error in analyze_crop: {e}")
        return jsonify({
            'error': 'Internal server error',
            'message': 'An unexpected error occurred',
            'status': 'error'
        }), 500

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus-style metrics endpoint"""
    try:
        memory = system_monitor.get_memory_usage()
        cpu = system_monitor.get_cpu_usage()
        uptime = time.time() - start_time
        
        metrics_data = f"""# HELP ml_server_uptime_seconds Server uptime in seconds
# TYPE ml_server_uptime_seconds counter
ml_server_uptime_seconds {uptime}

# HELP ml_server_memory_usage_percent Memory usage percentage
# TYPE ml_server_memory_usage_percent gauge
ml_server_memory_usage_percent {memory['used_percent']}

# HELP ml_server_cpu_usage_percent CPU usage percentage
# TYPE ml_server_cpu_usage_percent gauge
ml_server_cpu_usage_percent {cpu}

# HELP ml_server_model_loaded Model loaded status
# TYPE ml_server_model_loaded gauge
ml_server_model_loaded {1 if model_loaded else 0}

# HELP ml_server_requests_total Total number of requests
# TYPE ml_server_requests_total counter
ml_server_requests_total {sum(len(requests) for requests in user_requests.values())}
"""
        
        return metrics_data, 200, {'Content-Type': 'text/plain'}
    except Exception as e:
        logger.error(f"Metrics error: {e}")
        return f"# ERROR: {e}", 500, {'Content-Type': 'text/plain'}

if __name__ == '__main__':
    # Get port from environment variable (Render sets this)
    port = int(os.getenv('PORT', 5000))
    
    # Start server
    logger.info("🚀 Starting Krishi Sahayak ML Server...")
    logger.info(f"📊 Rate limit: {RATE_LIMIT_REQUESTS} requests per {RATE_LIMIT_WINDOW} seconds")
    logger.info(f"📁 Max file size: {MAX_FILE_SIZE / 1024 / 1024:.1f}MB")
    logger.info(f"🌐 Starting server on port {port}")
    
    # Use production WSGI server for Render
    try:
        import gunicorn.app.wsgiapp as wsgi
        logger.info("🚀 Starting with Gunicorn WSGI server...")
        num_workers = int(os.getenv('GUNICORN_WORKERS', '2')) # Default to 2 workers
        sys.argv = ['gunicorn', '--bind', f'0.0.0.0:{port}', '--workers', str(num_workers), '--timeout', '120', '--keep-alive', '2', '--max-requests', '1000', '--max-requests-jitter', '100', 'main_production:app']
        wsgi.run()
    except ImportError:
        logger.warning("⚠️ Gunicorn not available, falling back to Flask development server")
        logger.warning("⚠️ This is not recommended for production!")
        app.run(
            host='0.0.0.0',
            port=port,
            debug=False,
            threaded=True
        )