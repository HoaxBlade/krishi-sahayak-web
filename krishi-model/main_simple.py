#!/usr/bin/env python3
"""
Simplified ML Server for Krishi Sahayak - BEST_MODEL.H5 ONLY
This version only loads best_model.h5 and crop_type_labels.txt
"""

import os
import sys
import time
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from werkzeug.exceptions import RequestEntityTooLarge
import tensorflow as tf
import numpy as np
from PIL import Image
import io

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
model = None
labels = []
model_loaded = False
start_time = time.time()

# Initialize Flask app
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

def load_model_and_labels():
    """Load best_model.h5 and crop_type_labels.txt"""
    global model, labels, model_loaded
    
    try:
        logger.info("=== LOADING BEST_MODEL.H5 ===")
        
        # Set paths
        model_path = 'saved_models/best_model.h5'
        labels_path = 'labels.txt'  # Use disease labels instead of crop type labels
        
        # Check if files exist
        if not os.path.exists(model_path):
            logger.error(f"❌ Model file not found: {model_path}")
            return False
            
        if not os.path.exists(labels_path):
            logger.error(f"❌ Labels file not found: {labels_path}")
            return False
        
        # Load model
        logger.info("🤖 Loading best_model.h5...")
        model = tf.keras.models.load_model(model_path)
        logger.info(f"✅ Model loaded: {type(model)}")
        
        # Load labels
        logger.info("📝 Loading labels...")
        with open(labels_path, 'r') as f:
            labels = [line.strip() for line in f.readlines() if line.strip()]
        logger.info(f"✅ Loaded {len(labels)} labels: {labels}")
        
        model_loaded = True
        logger.info("🎉 === MODEL LOADING SUCCESS ===")
        return True
        
    except Exception as e:
        logger.error(f"❌ Failed to load model: {e}")
        import traceback
        logger.error(f"❌ Traceback: {traceback.format_exc()}")
        return False

def preprocess_image(image_data):
    """Preprocess image for model prediction"""
    try:
        # Open image
        image = Image.open(io.BytesIO(image_data))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Resize to 224x224 (standard for most models)
        image = image.resize((224, 224))
        
        # Convert to numpy array and normalize
        img_array = np.array(image) / 255.0
        
        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
        
    except Exception as e:
        logger.error(f"❌ Image preprocessing failed: {e}")
        return None

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    uptime = time.time() - start_time
    
    return jsonify({
        'status': 'healthy' if model_loaded else 'unhealthy',
        'timestamp': datetime.utcnow().isoformat(),
        'uptime_seconds': uptime,
        'model': {
            'loaded': model_loaded,
            'type': 'best_model.h5' if model_loaded else 'None',
            'labels_count': len(labels) if labels else 0
        }
    })

@app.route('/analyze_crop', methods=['POST'])
def analyze_crop():
    """Analyze crop from uploaded image"""
    global model, labels, model_loaded
    
    if not model_loaded:
        return jsonify({
            'error': 'Model not loaded',
            'status': 'error'
        }), 500
    
    try:
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({
                'error': 'No image file provided',
                'status': 'error'
            }), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({
                'error': 'No image file selected',
                'status': 'error'
            }), 400
        
        # Read image data
        image_data = file.read()
        
        # Preprocess image
        processed_image = preprocess_image(image_data)
        if processed_image is None:
            return jsonify({
                'error': 'Failed to process image',
                'status': 'error'
            }), 400
        
        # Make prediction
        logger.info("🔮 Making prediction...")
        predictions = model.predict(processed_image)
        
        # Get prediction results
        predicted_class_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_idx])
        predicted_disease = labels[predicted_class_idx] if predicted_class_idx < len(labels) else "Unknown"
        
        # Extract crop type and disease from the label (format: "Crop___Disease" or "Crop___Healthy")
        crop_type = "Unknown"
        disease_type = "Unknown"
        is_healthy = False
        
        if "___" in predicted_disease:
            parts = predicted_disease.split("___")
            crop_type = parts[0]
            disease_type = parts[1]
            is_healthy = "Healthy" in disease_type
        elif "_" in predicted_disease:
            # Handle cases like "Sugarcane_Bacterial Blight"
            parts = predicted_disease.split("_", 1)
            crop_type = parts[0]
            disease_type = parts[1]
            is_healthy = "Healthy" in disease_type
        
        logger.info(f"✅ Prediction: {predicted_disease} (confidence: {confidence:.4f})")
        logger.info(f"📊 Crop: {crop_type}, Disease: {disease_type}, Healthy: {is_healthy}")
        
        return jsonify({
            'prediction': predicted_disease,
            'crop_type': crop_type,
            'disease_type': disease_type,
            'is_healthy': is_healthy,
            'health_status': 'healthy' if is_healthy else 'unhealthy',
            'confidence': confidence,
            'prediction_class': int(predicted_class_idx),
            'all_predictions': {
                labels[i]: float(predictions[0][i]) 
                for i in range(min(len(labels), len(predictions[0])))
            },
            'status': 'success'
        })
        
    except Exception as e:
        logger.error(f"❌ Prediction failed: {e}")
        import traceback
        logger.error(f"❌ Traceback: {traceback.format_exc()}")
        return jsonify({
            'error': f'Prediction failed: {str(e)}',
            'status': 'error'
        }), 500

@app.errorhandler(RequestEntityTooLarge)
def handle_file_too_large(e):
    return jsonify({
        'error': 'File too large',
        'message': 'Maximum file size is 16MB',
        'status': 'error'
    }), 413

if __name__ == '__main__':
    logger.info("🚀 Starting Krishi ML Server (BEST_MODEL.H5 ONLY)")
    
    # Load model and labels
    if load_model_and_labels():
        logger.info("✅ Server ready to accept requests")
        app.run(host='0.0.0.0', port=5000, debug=False)
    else:
        logger.error("❌ Failed to load model. Server will not start.")
        sys.exit(1)
