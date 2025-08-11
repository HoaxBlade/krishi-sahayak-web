import os
import base64
import io
import numpy as np # type: ignore
from PIL import Image # type: ignore
import tensorflow as tf # type: ignore
from flask import Flask, request, jsonify # type: ignore
from flask_cors import CORS # type: ignore
import logging

# Import existing training utilities
from utils.dataloader import get_generators
from utils.train import train_model

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Global variable to store the trained model
model = None
labels = []

def load_labels():
    """Load crop labels from file"""
    try:
        # Try multiple possible locations for labels.txt
        label_paths = ["labels.txt", "notebooks/model/labels.txt", "model/labels.txt"]
        for path in label_paths:
            if os.path.exists(path):
                with open(path, 'r') as f:
                    return [line.strip() for line in f.readlines()]
        logger.error("No labels.txt found in any expected location")
        return []
    except Exception as e:
        logger.error(f"Error loading labels: {e}")
        return []

def preprocess_image(image_data):
    """Preprocess image for model input"""
    try:
        # Remove data URL prefix if present
        if image_data.startswith('data:image'):
            image_data = image_data.split(',')[1]
        
        # Decode base64 image
        image_bytes = base64.b64decode(image_data)
        image = Image.open(io.BytesIO(image_bytes))
        
        logger.info(f"Image loaded: {image.size} {image.mode}")
        
        # Resize to model input size (224x224 for MobileNetV2)
        image = image.resize((224, 224))
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

def analyze_crop(image_data):
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

@app.route('/analyze_crop', methods=['POST'])
def analyze_crop_endpoint():
    """Endpoint to analyze crop health from image"""
    try:
        logger.info("=== NEW CROP ANALYSIS REQUEST ===")
        logger.info(f"Request method: {request.method}")
        logger.info(f"Request headers: {dict(request.headers)}")
        
        if not request.is_json:
            logger.error("Request is not JSON")
            return jsonify({'error': 'Request must be JSON'}), 400
        
        data = request.get_json()
        logger.info(f"Request data keys: {list(data.keys()) if data else 'None'}")
        
        if 'image' not in data:
            logger.error("No image data in request")
            return jsonify({'error': 'No image data provided'}), 400
        
        image_data = data['image']
        logger.info(f"Image data received: {len(image_data)} characters")
        logger.info(f"Image data starts with: {image_data[:50]}...")
        
        if not model:
            logger.error("Model not loaded")
            return jsonify({'error': 'Model not available'}), 500
        
        # Analyze the crop
        result = analyze_crop(image_data)
        logger.info("=== CROP ANALYSIS COMPLETED ===")
        logger.info(f"Returning result: {result}")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in analyze_crop endpoint: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    logger.info("Health check requested")
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'labels_loaded': len(labels) > 0,
        'num_labels': len(labels)
    })

@app.route('/train', methods=['POST'])
def train_endpoint():
    """Endpoint to retrain the model"""
    logger.info("Model training requested")
    try:
        if not os.path.exists("Data"):
            return jsonify({'error': 'Training data not found'}), 400
        
        train_gen, val_gen, num_classes = get_generators("Data", "labels.txt")
        model, history = train_model(train_gen, val_gen, num_classes)
        
        # Save the trained model
        os.makedirs("model", exist_ok=True)
        model.save("model/mobilenetv2_model.h5")
        
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

def load_or_train_model():
    """Load existing model or train new one"""
    global model, labels
    
    logger.info("=== MODEL LOADING/TRAINING PROCESS ===")
    
    # Load labels first
    labels = load_labels()
    logger.info(f"Loaded {len(labels)} labels: {labels}")
    
    # Try to load existing model from multiple locations
    model_paths = [
        "model/best_model.h5",   
        # "model/mobilenetv2_model.h5",
        # "notebooks/model/mobilenetv2_model.h5",
        # "saved_models/mobilenetv2_model.h5"
    ]
    
    for model_path in model_paths:
        if os.path.exists(model_path):
            try:
                logger.info(f"Attempting to load model from: {model_path}")
                model = tf.keras.models.load_model(model_path)
                logger.info(f"Existing model loaded successfully from {model_path}")
                logger.info(f"Model summary: {model.summary()}")
                return True
            except Exception as e:
                logger.error(f"Error loading model from {model_path}: {e}")
                continue
    
    # If no existing model found, attempt to train new one
    logger.info("No existing model found. Attempting to train new model...")
    try:
        # Check if training data exists
        if not os.path.exists("Data"):
            logger.error("Training data directory 'Data' not found. Cannot train new model.")
            logger.error("Please ensure training data is available or use an existing model.")
            return False
            
        logger.info("Training data found, starting training process...")
        train_gen, val_gen, num_classes = get_generators("Data", "labels.txt")
        model, history = train_model(train_gen, val_gen, num_classes)
        
        # Save the trained model
        os.makedirs("model", exist_ok=True)
        model.save("model/mobilenetv2_model.h5")
        logger.info("New model trained and saved successfully")
        return True
    except Exception as e:
        logger.error(f"Error training model: {e}")
        return False

if __name__ == '__main__':
    logger.info("=== STARTING KRISHI ML SERVER ===")
    
    # Load or train the model when starting the server
    if load_or_train_model():
        logger.info("✅ Model ready for inference")
        logger.info("Starting Flask server on http://0.0.0.0:5001")
        logger.info("Available endpoints:")
        logger.info("  - POST /analyze_crop - Analyze crop image")
        logger.info("  - GET  /health - Check server health")
        logger.info("  - POST /train - Retrain model")
        logger.info("  - GET  /labels - Get available labels")
        
        app.run(host='0.0.0.0', port=5001, debug=True)
    else:
        logger.error("❌ Failed to load/train model. Server not started.")