import os
import base64
import io
import time
import threading
from collections import defaultdict, deque
import numpy as np # type: ignore
from PIL import Image # type: ignore
import tensorflow as tf # type: ignore
import logging
import psutil

from config import (
    RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW, MODEL_PATHS, LABEL_PATHS,
    MEMORY_HEALTH_THRESHOLD, CPU_HEALTH_THRESHOLD, IMAGE_SIZE, MAX_FILE_SIZE
)

logger = logging.getLogger(__name__)

class RateLimiter:
    """Simple rate limiter for user requests"""
    
    def __init__(self):
        self.user_requests = defaultdict(deque)
        self.lock = threading.Lock()

    def is_allowed(self, user_id):
        """Check if user is within rate limit"""
        current_time = time.time()
        
        with self.lock:
            # Clean old requests
            while self.user_requests[user_id] and self.user_requests[user_id][0] < current_time - RATE_LIMIT_WINDOW:
                self.user_requests[user_id].popleft()
            
            # Check if under limit
            if len(self.user_requests[user_id]) >= RATE_LIMIT_REQUESTS:
                return False
            
            # Add current request
            self.user_requests[user_id].append(current_time)
            return True
    
    def get_remaining_requests(self, user_id):
        """Get remaining requests for user"""
        current_time = time.time()
        
        with self.lock:
            # Clean old requests
            while self.user_requests[user_id] and self.user_requests[user_id][0] < current_time - RATE_LIMIT_WINDOW:
                self.user_requests[user_id].popleft()
            
            return max(0, RATE_LIMIT_REQUESTS - len(self.user_requests[user_id]))

class MLQueueManager:
    """Manages the request queue and processing lock for ML tasks."""
    def __init__(self):
        self.request_queue = deque()
        self.queue_lock = threading.Lock()
        self.processing_lock = threading.Lock()

    def get_queue_size(self):
        with self.queue_lock:
            return len(self.request_queue)

    def is_processing_locked(self):
        return self.processing_lock.locked()

    def acquire_processing_lock(self):
        return self.processing_lock.acquire()

    def release_processing_lock(self):
        self.processing_lock.release()

class SystemMonitor:
    """Monitor system resources"""
    
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
        """Check if system resources are healthy"""
        memory_usage = SystemMonitor.get_memory_usage()['used_percent']
        cpu_usage = SystemMonitor.get_cpu_usage()
        
        return memory_usage < MEMORY_HEALTH_THRESHOLD and cpu_usage < CPU_HEALTH_THRESHOLD

def load_labels():
    """Load crop labels from file"""
    try:
        for path in LABEL_PATHS:
            if os.path.exists(path):
                with open(path, 'r') as f:
                    labels = [line.strip() for line in f.readlines()]
                    if not labels:
                        logger.warning(f"Labels file '{path}' found but is empty.")
                    return labels
        logger.error("No labels.txt found in any expected location. Returning empty list.")
        return []
    except Exception as e:
        logger.error(f"Error loading labels: {e}. Returning empty list.")
        return []

def preprocess_image(image_data):
    """Preprocess image for model input"""
    try:
        # Handle both file upload (PIL Image object) and base64 string
        if isinstance(image_data, Image.Image):
            image = image_data
        elif isinstance(image_data, str):
            # Remove data URL prefix if present
            if image_data.startswith('data:image'):
                image_data = image_data.split(',')[1]
            
            # Decode base64 image
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
        else:
            raise ValueError("Unsupported image data type. Must be PIL Image or base64 string.")
        
        logger.info(f"Image loaded: {image.size} {image.mode}")
        
        # Convert to RGB if not already
        if image.mode != 'RGB':
            image = image.convert('RGB')

        # Resize to model input size
        image = image.resize(IMAGE_SIZE)
        logger.info(f"Image resized to: {image.size}")
        
        # Convert to numpy array and normalize
        image_array = np.array(image) / 255.0
        
        # Add batch dimension
        image_array = np.expand_dims(image_array, axis=0)
        
        logger.info(f"Image preprocessed: shape={image_array.shape}, dtype={image_array.dtype}")
        return image_array
        
    except Exception as e:
        logger.error(f"Error preprocessing image: {e}")
        raise

def load_ml_model():
    """Load the ML model from common paths and run warm-up inference."""
    model = None
    for model_path in MODEL_PATHS:
        if os.path.exists(model_path):
            try:
                logger.info(f"Attempting to load model from: {model_path}")
                model = tf.keras.models.load_model(model_path)
                # Warm-up for lower p95 latency
                _ = model.predict(np.zeros((1, IMAGE_SIZE[0], IMAGE_SIZE[1], 3), dtype=np.float32), verbose=0)
                logger.info(f"✅ Model loaded and warmed from {model_path}")
                return model
            except Exception as e:
                logger.error(f"Error loading model from {model_path}: {e}")
                continue
    logger.error("❌ No valid model file found in known paths")
    return None

def analyze_crop_prediction(model, image_data, labels):
    """Analyze crop health using the loaded model"""
    try:
        logger.info("Starting crop analysis...")
        
        # Preprocess the image
        processed_image = preprocess_image(image_data)
        logger.info("Image preprocessing completed")
        
        # Make prediction
        logger.info("Making model prediction...")
        predictions = model.predict(processed_image, verbose=0)
        logger.info(f"Model prediction completed: shape={predictions.shape}")
        
        # Get the predicted class
        predicted_class = np.argmax(predictions[0])
        confidence = np.max(predictions[0])
        
        # Get the predicted label
        predicted_label = labels[predicted_class] if predicted_class < len(labels) else "Unknown"
        
        # Determine if crop is healthy (assuming labels ending with "Healthy" are healthy)
        is_healthy = predicted_label.endswith("Healthy")
        
        logger.info(f"Prediction results:")
        logger.info(f"  - Predicted class: {predicted_class}")
        logger.info(f"  - Predicted label: {predicted_label}")
        logger.info(f"  - Confidence: {confidence:.4f}")
        logger.info(f"  - Is healthy: {is_healthy}")
        logger.info(f"  - All predictions: {predictions[0].tolist()}")
        
        return {
            'prediction_class': int(predicted_class),
            'crop_type': predicted_label,
            'confidence': float(confidence),
            'is_healthy': is_healthy,
            'all_predictions': predictions[0].tolist()
        }
        
    except Exception as e:
        logger.error(f"Error in crop analysis: {e}")
        raise