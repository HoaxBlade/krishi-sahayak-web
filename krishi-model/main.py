import os
import time
import logging
from flask import Flask, request, jsonify # type: ignore
from flask_cors import CORS # type: ignore

# Import utilities from ml_utils and config
import ml_utils
from ml_utils import RateLimiter, SystemMonitor, load_labels, preprocess_image, analyze_crop_prediction, load_ml_model
from config import RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW, FLASK_PORT, FLASK_HOST, MEMORY_HEALTH_THRESHOLD, CPU_HEALTH_THRESHOLD

# Import existing training utilities
from utils.dataloader import get_generators
from utils.train import train_model

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Global variable to store the trained model and labels
model = None
labels = []

# Record start time
start_time = time.time()

@app.route('/analyze_crop', methods=['POST'])
def analyze_crop_endpoint():
    """Endpoint to analyze crop health from image"""
    global model, labels
    try:
        logger.info("=== NEW CROP ANALYSIS REQUEST ===")
        user_id = request.headers.get('X-User-ID', request.remote_addr)
        
        if not RateLimiter.is_allowed(user_id):
            remaining = RateLimiter.get_remaining_requests(user_id)
            logger.warning(f"Rate limit exceeded for user {user_id}")
            return jsonify({
                'error': 'Rate limit exceeded',
                'message': f'Maximum {RATE_LIMIT_REQUESTS} requests per minute allowed',
                'remaining_requests': remaining,
                'retry_after': RATE_LIMIT_WINDOW
            }), 429
        
        if not SystemMonitor.is_system_healthy():
            logger.warning("System resources unhealthy, rejecting request")
            return jsonify({
                'error': 'Server overloaded',
                'message': 'Please try again later',
                'memory_usage': SystemMonitor.get_memory_usage()['used_percent'],
                'cpu_usage': SystemMonitor.get_cpu_usage()
            }), 503
        
        if not request.is_json:
            logger.error("Request is not JSON")
            return jsonify({'error': 'Request must be JSON'}), 400
        
        data = request.get_json()
        if 'image' not in data:
            logger.error("No image data in request")
            return jsonify({'error': 'No image data provided'}), 400
        
        image_data = data['image']
        
        if model is None:
            logger.error("Model not loaded")
            return jsonify({'error': 'Model not available'}), 500
        
        with ml_utils.processing_lock: # Access from ml_utils module
            result = analyze_crop_prediction(model, image_data, labels)
            logger.info("=== CROP ANALYSIS COMPLETED ===")
            
            result['system_info'] = {
                'memory_usage': SystemMonitor.get_memory_usage()['used_percent'],
                'cpu_usage': SystemMonitor.get_cpu_usage(),
                'remaining_requests': RateLimiter.get_remaining_requests(user_id)
            }
            
            return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in analyze_crop endpoint: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Enhanced health check endpoint"""
    global model, labels
    logger.info("Health check requested")
    
    system_healthy = SystemMonitor.is_system_healthy()
    memory_usage = SystemMonitor.get_memory_usage()['used_percent']
    cpu_usage = SystemMonitor.get_cpu_usage()
    
    model_loaded = model is not None
    labels_loaded = len(labels) > 0
    
    overall_healthy = system_healthy and model_loaded and labels_loaded
    
    status = 'healthy' if overall_healthy else 'unhealthy'
    
    return jsonify({
        'status': status,
        'timestamp': time.time(),
        'model': {
            'loaded': model_loaded,
            'labels_loaded': labels_loaded,
            'num_labels': len(labels)
        },
        'system': {
            'memory_usage_percent': memory_usage,
            'cpu_usage_percent': cpu_usage,
            'healthy': system_healthy
        },
        'rate_limiting': {
            'requests_per_minute': RATE_LIMIT_REQUESTS,
            'active_users': len(ml_utils.user_requests) # Access from ml_utils module
        }
    })

@app.route('/train', methods=['POST'])
def train_endpoint():
    """Endpoint to retrain the model"""
    global model, labels
    logger.info("Model training requested")
    try:
        if not os.path.exists("Data"):
            return jsonify({'error': 'Training data not found'}), 400
        
        train_gen, val_gen, num_classes = get_generators("Data", "labels.txt")
        model, history = train_model(train_gen, val_gen, num_classes)
        
        # Save the trained model
        os.makedirs("model", exist_ok=True)
        model.save("model/mobilenetv2_model.h5")
        
        # Reload labels in case they changed during training
        labels = load_labels()

        logger.info("Model training completed successfully")
        return jsonify({'message': 'Model trained successfully'})
        
    except Exception as e:
        logger.error(f"Error in training: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/labels', methods=['GET'])
def get_labels():
    """Get available crop labels"""
    logger.info("Labels requested")
    return jsonify({'labels': labels})

@app.route('/status', methods=['GET'])
def get_status():
    """Get detailed server status"""
    global model, labels
    logger.info("Status requested")
    
    memory_usage = SystemMonitor.get_memory_usage()['used_percent']
    cpu_usage = SystemMonitor.get_cpu_usage()
    
    active_users = len(ml_utils.user_requests) # Access from ml_utils module
    
    with ml_utils.queue_lock: # Access from ml_utils module
        queue_size = len(ml_utils.request_queue) # Access from ml_utils module
    
    return jsonify({
        'server_status': 'running',
        'timestamp': time.time(),
        'uptime': time.time() - start_time,
        'system': {
            'memory_usage_percent': memory_usage,
            'cpu_usage_percent': cpu_usage,
            'healthy': SystemMonitor.is_system_healthy()
        },
        'model': {
            'loaded': model is not None,
            'labels_count': len(labels)
        },
        'rate_limiting': {
            'requests_per_minute': RATE_LIMIT_REQUESTS,
            'active_users': active_users,
            'window_seconds': RATE_LIMIT_WINDOW
        },
        'queue': {
            'size': queue_size,
            'processing': ml_utils.processing_lock.locked() # Access from ml_utils module
        }
    })

def initialize_model_and_labels():
    """Initialize model and labels on server startup."""
    global model, labels
    logger.info("=== MODEL LOADING/TRAINING PROCESS ===")
    
    labels = load_labels()
    logger.info(f"Loaded {len(labels)} labels: {labels}")
    
    model = load_ml_model()
    
    if model is None:
        logger.info("No existing model found. Attempting to train new model...")
        try:
            if not os.path.exists("Data"):
                logger.error("Training data directory 'Data' not found. Cannot train new model.")
                logger.error("Please ensure training data is available or use an existing model.")
                return False
                
            logger.info("Training data found, starting training process...")
            train_gen, val_gen, num_classes = get_generators("Data", "labels.txt")
            model, history = train_model(train_gen, val_gen, num_classes)
            
            os.makedirs("model", exist_ok=True)
            model.save("model/mobilenetv2_model.h5")
            logger.info("New model trained and saved successfully")
            return True
        except Exception as e:
            logger.error(f"Error training model: {e}")
            return False
    return True

if __name__ == '__main__':
    logger.info("=== STARTING KRISHI ML SERVER ===")
    
    if initialize_model_and_labels():
        logger.info("✅ Model ready for inference")
        logger.info(f"Starting Flask server on http://{FLASK_HOST}:{FLASK_PORT}")
        logger.info("Available endpoints:")
        logger.info("  - POST /analyze_crop - Analyze crop image")
        logger.info("  - GET  /health - Check server health")
        logger.info("  - GET  /status - Get detailed server status")
        logger.info("  - POST /train - Retrain model")
        logger.info("  - GET  /labels - Get available labels")
        logger.info(f"Rate limiting: {RATE_LIMIT_REQUESTS} requests/{RATE_LIMIT_WINDOW} seconds per user")
        logger.info(f"System monitoring: Memory < {MEMORY_HEALTH_THRESHOLD}%, CPU < {CPU_HEALTH_THRESHOLD}%")
        
        app.run(host=FLASK_HOST, port=FLASK_PORT, debug=False)
    else:
        logger.error("❌ Failed to load/train model. Server not started.")