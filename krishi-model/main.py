import os
import time
import logging
from flask import Flask, request, jsonify # type: ignore
from flask_cors import CORS # type: ignore
from werkzeug.exceptions import RequestEntityTooLarge # type: ignore
from PIL import Image # type: ignore
from transformers import pipeline # type: ignore

# Import utilities from ml_utils and config
import ml_utils
from ml_utils import load_labels, preprocess_image, analyze_crop_prediction, load_ml_model, RateLimiter, SystemMonitor, MLQueueManager, get_gemini_crop_analysis
from config import RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW, FLASK_PORT, FLASK_HOST, MEMORY_HEALTH_THRESHOLD, CPU_HEALTH_THRESHOLD, MAX_FILE_SIZE

# Import existing training utilities
from utils.dataloader import get_generators
from utils.train import train_model

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

@app.errorhandler(RequestEntityTooLarge)
def handle_file_too_large(e):
    return jsonify({
        'error': 'File too large',
        'message': f'Maximum file size is {MAX_FILE_SIZE / 1024 / 1024:.1f}MB',
        'status': 'error'
    }), 413

# Initialize components
rate_limiter = RateLimiter()
system_monitor = SystemMonitor()
ml_queue_manager = MLQueueManager()

# Global variable to store the trained model and labels
model = None
labels = []

# Initialize the translation pipeline globally
translator_pipeline = pipeline("translation", model="Helsinki-NLP/opus-mt-en-hi")

# Record start time
start_time = time.time()

# --- Translation Function ---
def translate_text(text: str, target_language: str = 'hi') -> str:
    """
    Translates the input English text to the target language (default: Hindi).
    """
    if target_language == 'hi':
        result = translator_pipeline(text)
        hindi_translation = result[0]['translation_text']
        return hindi_translation
    else:
        # For now, only Hindi is supported. Can be extended later.
        logger.warning(f"Translation to {target_language} is not supported yet. Returning original text.")
        return text

@app.route('/analyze_crop', methods=['POST'])
async def analyze_crop_endpoint():
    """Endpoint to analyze crop health from image"""
    global model, labels
    try:
        logger.info("=== NEW CROP ANALYSIS REQUEST ===")
        user_id = request.headers.get('X-User-ID', request.remote_addr)
        
        if not rate_limiter.is_allowed(user_id):
            remaining = rate_limiter.get_remaining_requests(user_id)
            logger.warning(f"Rate limit exceeded for user {user_id}")
            return jsonify({
                'error': 'Rate limit exceeded',
                'message': f'Maximum {RATE_LIMIT_REQUESTS} requests per minute allowed',
                'remaining_requests': remaining,
                'retry_after': RATE_LIMIT_WINDOW
            }), 429
        
        if not system_monitor.is_system_healthy():
            logger.warning("System resources unhealthy, rejecting request")
            return jsonify({
                'error': 'Server overloaded',
                'message': 'Please try again later',
                'memory_usage': system_monitor.get_memory_usage()['used_percent'],
                'cpu_usage': system_monitor.get_cpu_usage()
            }), 503
        
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
            logger.error("No image data in request")
            return jsonify({
                'error': 'No image provided',
                'message': 'Please provide an image file or base64 image data',
                'status': 'error'
            }), 400
        
        image_data = image_data_input
        
        if model is None:
            logger.error("Model not loaded")
            return jsonify({
                'error': 'Model not available',
                'message': 'The ML model is not loaded or initialized.',
                'status': 'error'
            }), 500
        
        with ml_queue_manager.processing_lock:
            model_or_interpreter, is_tflite_model = model # Unpack the model and its type
            result = analyze_crop_prediction(model_or_interpreter, image_data, labels, is_tflite_model)
            logger.info("=== CROP ANALYSIS COMPLETED ===")
            
            # Fetch Gemini analysis
            disease_label = result.get('crop_type', 'Unknown')
            gemini_analysis_english = await get_gemini_crop_analysis(disease_label)
            
            # Translate Gemini analysis to Hindi
            gemini_analysis_hindi = translate_text(gemini_analysis_english, 'hi')
            
            result['gemini_analysis_english'] = gemini_analysis_english
            result['gemini_analysis_hindi'] = gemini_analysis_hindi
            
            result['system_info'] = {
                'memory_usage': system_monitor.get_memory_usage()['used_percent'],
                'cpu_usage': system_monitor.get_cpu_usage(),
                'remaining_requests': rate_limiter.get_remaining_requests(user_id)
            }
            result['status'] = 'success'
            
            return jsonify(result)
        
    except Exception as e:
        logger.error(f"Unexpected error in analyze_crop endpoint: {e}")
        return jsonify({
            'error': 'Internal server error',
            'message': 'An unexpected error occurred',
            'status': 'error'
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Enhanced health check endpoint"""
    global model, labels
    logger.info("Health check requested")
    
    system_healthy = system_monitor.is_system_healthy()
    memory_usage = system_monitor.get_memory_usage()['used_percent']
    cpu_usage = system_monitor.get_cpu_usage()
    
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
            'active_users': len(rate_limiter.user_requests)
        }
    })

@app.route('/train', methods=['POST'])
def train_endpoint():
    """Endpoint to retrain the model"""
    global model, labels
    logger.info("Model training requested")
    try:
        if not os.path.exists("Data"):
            logger.error("Training data directory 'Data' not found.")
            return jsonify({
                'error': 'Training data not found',
                'message': 'The "Data" directory for training is missing.',
                'status': 'error'
            }), 400
        
        train_gen, val_gen, num_classes = get_generators("Data", "labels.txt")
        model, history = train_model(train_gen, val_gen, num_classes)
        
        # Save the trained model
        os.makedirs("model", exist_ok=True)
        model.save("model/mobilenetv2_model.h5")
        
        # Reload labels in case they changed during training
        labels = load_labels()

        logger.info("Model training completed successfully")
        return jsonify({'message': 'Model trained successfully', 'status': 'success'})
        
    except Exception as e:
        logger.error(f"Error in training endpoint: {e}")
        return jsonify({
            'error': 'Training failed',
            'message': f'An error occurred during model training: {str(e)}',
            'status': 'error'
        }), 500

@app.route('/labels', methods=['GET'])
def get_labels():
    """Get available crop labels"""
    logger.info("Labels requested")
    return jsonify({'labels': labels, 'status': 'success'})

@app.route('/status', methods=['GET'])
def get_status():
    """Get detailed server status"""
    global model, labels
    logger.info("Status requested")
    
    memory_usage = system_monitor.get_memory_usage()['used_percent']
    cpu_usage = system_monitor.get_cpu_usage()
    
    active_users = len(rate_limiter.user_requests)
    
    queue_size = ml_queue_manager.get_queue_size()
    
    return jsonify({
        'server_status': 'running',
        'timestamp': time.time(),
        'uptime': time.time() - start_time,
        'system': {
            'memory_usage_percent': memory_usage,
            'cpu_usage_percent': cpu_usage,
            'healthy': system_monitor.is_system_healthy()
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
            'processing': ml_queue_manager.is_processing_locked()
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