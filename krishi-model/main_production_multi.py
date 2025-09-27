#!/usr/bin/env python3
"""
Production ML Server for Krishi Sahayak - Multi-Model Version
Supports all 8 specialized models with intelligent routing
"""

import os
import sys
import time
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from werkzeug.exceptions import RequestEntityTooLarge
from PIL import Image
import io
import base64

# Import utilities from ml_utils and config
import ml_utils
from ml_utils import load_labels, preprocess_image, RateLimiter, SystemMonitor, MLQueueManager
from config import (
    RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW, MAX_FILE_SIZE, IMAGE_SIZE,
    MEMORY_HEALTH_THRESHOLD, CPU_HEALTH_THRESHOLD, FLASK_PORT, FLASK_HOST
)

# Import MultiModelManager
from multi_model_manager import MultiModelManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global variables
multi_model_manager = None
fallback_model = None
fallback_labels = []
model_loaded = False
start_time = time.time()

# Initialize Flask app
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Initialize models when Flask app starts
@app.before_first_request
def initialize_models():
    """Initialize models when Flask app starts (for Gunicorn workers)"""
    global multi_model_manager, fallback_model, fallback_labels, model_loaded
    
    if not model_loaded:
        logger.info("🔄 Initializing models in worker process...")
        initialize_multi_model_system()

# Initialize components
rate_limiter = RateLimiter()
system_monitor = SystemMonitor()
ml_queue_manager = MLQueueManager()

def initialize_multi_model_system():
    """Initialize the multi-model system with all 8 specialized models"""
    global multi_model_manager, fallback_model, fallback_labels, model_loaded
    
    logger.info("=== MULTI-MODEL SYSTEM INITIALIZATION ===")
    logger.info(f"📁 Working directory: {os.getcwd()}")
    logger.info(f"📁 Available files: {os.listdir('.')}")
    
    try:
        # Initialize MultiModelManager
        logger.info("🚀 Initializing MultiModelManager...")
        multi_model_manager = MultiModelManager()
        
        # Load all specialized models
        success = multi_model_manager.initialize()
        
        if success:
            logger.info("✅ MultiModelManager initialized successfully")
            model_status = multi_model_manager.get_model_status()
            logger.info(f"📊 Models loaded: {model_status['total_models_loaded']}")
            logger.info(f"📊 Available crops: {multi_model_manager.get_available_crops()}")
            
            # Load fallback model for compatibility
            logger.info("🔄 Loading fallback model...")
            fallback_model, _, _ = ml_utils.load_ml_model()
            fallback_labels = load_labels()
            
            model_loaded = True
            logger.info("✅ Multi-model system ready!")
            return True
        else:
            logger.error("❌ MultiModelManager initialization failed")
            return False
            
    except Exception as e:
        logger.error(f"❌ Multi-model initialization failed: {e}")
        import traceback
        logger.error(f"❌ Traceback: {traceback.format_exc()}")
        return False

def ensure_model_loaded():
    """Ensure multi-model system is loaded"""
    global model_loaded
    if not model_loaded:
        logger.info("🔄 Multi-model system not loaded, initializing...")
        return initialize_multi_model_system()
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
    """Enhanced health check for multi-model system"""
    global model_loaded
    try:
        memory = system_monitor.get_memory_usage()
        cpu = system_monitor.get_cpu_usage()
        uptime = time.time() - start_time
        
        # Get multi-model status
        multi_model_status = {}
        if multi_model_manager:
            multi_model_status = multi_model_manager.get_model_status()
        
        return jsonify({
            'status': 'healthy' if model_loaded and system_monitor.is_system_healthy() else 'unhealthy',
            'timestamp': datetime.utcnow().isoformat(),
            'uptime_seconds': uptime,
            'multi_model_system': multi_model_status,
            'available_crops': multi_model_manager.get_available_crops() if multi_model_manager else [],
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

@app.route('/models/status', methods=['GET'])
def get_models_status():
    """Get detailed status of all models"""
    try:
        if not multi_model_manager:
            return jsonify({'error': 'Multi-model system not initialized'}), 500
        
        status = multi_model_manager.get_model_status()
        available_crops = multi_model_manager.get_available_crops()
        
        return jsonify({
            'status': 'success',
            'multi_model_system': status,
            'available_crops': available_crops,
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        logger.error(f"Models status error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/models/available_crops', methods=['GET'])
def get_available_crops():
    """Get list of available crop types"""
    try:
        if not multi_model_manager:
            return jsonify({'error': 'Multi-model system not initialized'}), 500
        
        crops = multi_model_manager.get_available_crops()
        return jsonify({
            'status': 'success',
            'available_crops': crops,
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        logger.error(f"Available crops error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/analyze_crop', methods=['POST'])
def analyze_crop_endpoint():
    """Analyze crop image using multi-model system"""
    global model_loaded
    start_time_req = time.time()
    
    try:
        # Ensure models are loaded
        if not ensure_model_loaded():
            return jsonify({
                'error': 'Model system not available',
                'message': 'Multi-model system failed to initialize',
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
        
        # Process image input
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
        
        # Use multi-model system for analysis
        logger.info("🔍 Starting multi-model analysis...")
        result = multi_model_manager.analyze_crop_two_stage(image_data_input)
        
        processing_time = time.time() - start_time_req
        logger.info(f"✅ Multi-model analysis completed in {processing_time:.2f}s")
        
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

@app.route('/analyze_crop_direct', methods=['POST'])
def analyze_crop_direct_endpoint():
    """Direct crop analysis with optional crop type specification"""
    global model_loaded
    start_time_req = time.time()
    
    try:
        # Ensure models are loaded
        if not ensure_model_loaded():
            return jsonify({
                'error': 'Model system not available',
                'message': 'Multi-model system failed to initialize',
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
        
        # Get crop type from request
        crop_type = None
        if request.is_json and 'crop_type' in request.get_json():
            crop_type = request.get_json()['crop_type']
        
        # Process image input
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
        
        # Use direct analysis
        logger.info(f"🔍 Starting direct analysis for crop: {crop_type}")
        result = multi_model_manager.analyze_crop_direct(image_data_input, crop_type)
        
        processing_time = time.time() - start_time_req
        logger.info(f"✅ Direct analysis completed in {processing_time:.2f}s")
        
        result['processing_time_seconds'] = processing_time
        result['system_info'] = {
            'memory_usage_percent': system_monitor.get_memory_usage()['used_percent'],
            'cpu_usage_percent': system_monitor.get_cpu_usage()
        }
        result['status'] = 'success'
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Unexpected error in analyze_crop_direct_endpoint: {e}")
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
        
        # Get model counts
        total_models = 0
        if multi_model_manager:
            model_status = multi_model_manager.get_model_status()
            total_models = model_status.get('total_models_loaded', 0)
        
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

# HELP ml_server_models_total Total number of models loaded
# TYPE ml_server_models_total gauge
ml_server_models_total {total_models}

# HELP ml_server_requests_total Total number of requests
# TYPE ml_server_requests_total counter
ml_server_requests_total {sum(len(requests) for requests in rate_limiter.user_requests.values())}
"""
        
        return metrics_data, 200, {'Content-Type': 'text/plain'}
    except Exception as e:
        logger.error(f"Metrics error: {e}")
        return f"# ERROR: {e}", 500, {'Content-Type': 'text/plain'}

if __name__ == '__main__':
    logger.info("🚀 Starting Krishi Sahayak Multi-Model ML Server...")
    logger.info(f"📊 Rate limit: {RATE_LIMIT_REQUESTS} requests per {RATE_LIMIT_WINDOW} seconds")
    logger.info(f"📁 Max file size: {MAX_FILE_SIZE / 1024 / 1024:.1f}MB")
    logger.info(f"🌐 Starting server on port {FLASK_PORT}")
    
    if initialize_multi_model_system():
        logger.info("✅ Multi-model system initialized successfully")
        logger.info("Available endpoints:")
        logger.info("  - POST /analyze_crop - Two-stage analysis (crop detection + disease)")
        logger.info("  - POST /analyze_crop_direct - Direct analysis with optional crop type")
        logger.info("  - GET  /health - Check server health")
        logger.info("  - GET  /models/status - Get detailed model status")
        logger.info("  - GET  /models/available_crops - Get available crop types")
        logger.info("  - GET  /metrics - Prometheus metrics")
        
        try:
            import gunicorn.app.wsgiapp as wsgi
            logger.info("🚀 Starting with Gunicorn WSGI server...")
            sys.argv = ['gunicorn', '--bind', f'{FLASK_HOST}:{FLASK_PORT}', '--workers', '1', '--worker-class', 'gthread', '--threads', '2', '--timeout', '300', '--keep-alive', '5', '--max-requests', '1000', '--max-requests-jitter', '100', 'main_production_multi:app']
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
        logger.error("❌ Failed to initialize multi-model system. Server not started.")
