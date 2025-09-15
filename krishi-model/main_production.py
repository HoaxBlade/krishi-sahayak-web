#!/usr/bin/env python3
"""
Production ML Server for Krishi Sahayak
Optimized for Kubernetes deployment with proper logging and monitoring
"""

import os
import sys
import time
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from werkzeug.exceptions import RequestEntityTooLarge

# Import utilities from ml_utils and config
import ml_utils
from ml_utils import RateLimiter, SystemMonitor, load_labels, preprocess_image, analyze_crop_prediction, load_ml_model
from config import (
    RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW, MAX_FILE_SIZE, IMAGE_SIZE,
    MEMORY_HEALTH_THRESHOLD, CPU_HEALTH_THRESHOLD, FLASK_PORT, FLASK_HOST
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global variables for model and labels
model = None
labels = []
model_loaded = False
start_time = time.time()

# Initialize Flask app
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Initialize components
rate_limiter = RateLimiter()
system_monitor = SystemMonitor()

def initialize_production_model_and_labels():
    """Initialize model and labels for production server."""
    global model, labels, model_loaded
    logger.info("=== PRODUCTION MODEL LOADING PROCESS ===")
    
    labels = load_labels()
    logger.info(f"Loaded {len(labels)} labels: {labels}")
    
    model = load_ml_model()
    model_loaded = (model is not None)
    
    if not model_loaded:
        logger.error("❌ Failed to load model for production. Server will not start.")
    return model_loaded

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
    global model_loaded
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
                'cpu_percent': cpu
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
    global model_loaded
    try:
        memory = system_monitor.get_memory_usage()
        cpu = system_monitor.get_cpu_usage()
        uptime = time.time() - start_time
        
        with ml_utils.queue_lock: # Access from ml_utils module
            queue_size = len(ml_utils.request_queue) # Access from ml_utils module
        
        with rate_limiter.lock: # Use rate_limiter's internal lock
            active_users = len(ml_utils.user_requests) # Access from ml_utils module
        
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
                'processing': ml_utils.processing_lock.locked() # Access from ml_utils module
            }
        })
    except Exception as e:
        logger.error(f"Status check error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/analyze_crop', methods=['POST'])
def analyze_crop_endpoint():
    """Analyze crop image for disease detection"""
    global model, labels, model_loaded
    start_time_req = time.time()
    
    try:
        if not model_loaded or model is None:
            logger.error("Model not loaded, cannot process request.")
            return jsonify({
                'error': 'Model not available',
                'message': 'The ML model is not loaded or initialized.',
                'status': 'error'
            }), 500

        if not system_monitor.is_system_healthy():
            return jsonify({
                'error': 'Server overloaded',
                'message': 'Server is currently under heavy load. Please try again later.',
                'status': 'error'
            }), 503
        
        user_id = request.headers.get('X-User-ID', request.remote_addr)
        
        if not rate_limiter.is_allowed(user_id):
            remaining = rate_limiter.get_remaining_requests(user_id)
            return jsonify({
                'error': 'Rate limit exceeded',
                'message': f'Too many requests. Try again in {RATE_LIMIT_WINDOW // 60} minutes.',
                'remaining_requests': remaining,
                'status': 'error'
            }), 429
        
        image_data_input = None
        
        if 'image' in request.files:
            image_file = request.files['image']
            if image_file.filename != '':
                try:
                    image_data_input = Image.open(image_file.stream)
                except Exception as e:
                    logger.error(f"File upload processing error: {e}")
                    return jsonify({
                        'error': 'Invalid image file',
                        'message': 'Could not process the uploaded image file',
                        'status': 'error'
                    }), 400
        
        elif request.is_json and 'image' in request.get_json():
            image_data_input = request.get_json()['image']
        
        if image_data_input is None:
            return jsonify({
                'error': 'No image provided',
                'message': 'Please provide an image file or base64 image data',
                'status': 'error'
            }), 400
        
        # Use the shared analysis function
        result = analyze_crop_prediction(model, image_data_input, labels)
        
        processing_time = time.time() - start_time_req
        
        logger.info(f"Crop analysis completed for user {user_id} in {processing_time:.2f}s")
        
        result['processing_time_seconds'] = processing_time
        result['system_info'] = {
            'memory_usage_percent': system_monitor.get_memory_usage()['used_percent'],
            'cpu_usage_percent': system_monitor.get_cpu_usage()
        }
        result['status'] = 'success'
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Unexpected error in analyze_crop_endpoint: {e}")
        return jsonify({
            'error': 'Internal server error',
            'message': 'An unexpected error occurred',
            'status': 'error'
        }), 500

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus-style metrics endpoint"""
    global model_loaded
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
ml_server_requests_total {sum(len(requests) for requests in ml_utils.user_requests.values())}
"""
        
        return metrics_data, 200, {'Content-Type': 'text/plain'}
    except Exception as e:
        logger.error(f"Metrics error: {e}")
        return f"# ERROR: {e}", 500, {'Content-Type': 'text/plain'}

if __name__ == '__main__':
    if initialize_production_model_and_labels():
        logger.info("🚀 Starting Krishi Sahayak ML Server...")
        logger.info(f"📊 Rate limit: {RATE_LIMIT_REQUESTS} requests per {RATE_LIMIT_WINDOW} seconds")
        logger.info(f"📁 Max file size: {MAX_FILE_SIZE / 1024 / 1024:.1f}MB")
        logger.info(f"🌐 Starting server on port {FLASK_PORT}")
        
        try:
            import gunicorn.app.wsgiapp as wsgi
            logger.info("🚀 Starting with Gunicorn WSGI server...")
            num_workers = int(os.getenv('GUNICORN_WORKERS', '2'))
            sys.argv = ['gunicorn', '--bind', f'{FLASK_HOST}:{FLASK_PORT}', '--workers', str(num_workers), '--timeout', '120', '--keep-alive', '2', '--max-requests', '1000', '--max-requests-jitter', '100', 'main_production:app']
            wsgi.run()
        except ImportError:
            logger.warning("⚠️ Gunicorn not available, falling back to Flask development server")
            logger.warning("⚠️ This is not recommended for production!")
            app.run(
                host=FLASK_HOST,
                port=FLASK_PORT,
                debug=False,
                threaded=True
            )
    else:
        logger.error("❌ Failed to initialize model. Server not started.")