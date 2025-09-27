#!/usr/bin/env python3
"""
Multi-Model Manager for Krishi Sahayak
Manages multiple specialized models for crop type detection and disease analysis
"""

import os
import logging
import numpy as np
from typing import Dict, List, Tuple, Optional, Union
import tensorflow as tf
import tensorflow.lite as tflite
from PIL import Image

logger = logging.getLogger(__name__)

class MultiModelManager:
    """Manages multiple specialized models for crop analysis"""
    
    def __init__(self):
        self.crop_detector = None
        self.disease_models = {
            'corn': None,
            'wheat': None,
            'rice': None,
            'potato': None,
            'sugarcane': None
        }
        self.fallback_models = []
        self.model_labels = {}
        self.model_status = {}
        self.is_initialized = False
        
        # Model paths configuration
        self.model_paths = {
            'crop_detector': 'saved_models/crop_detector_model.h5',
            'corn_disease': 'saved_models/corn_disease_detector_model.h5',
            'wheat_disease': 'saved_models/wheat_disease_detector_model.h5',
            'rice_disease': 'saved_models/rice_disease_detector_model.h5',
            'potato_disease': 'saved_models/potato_disease_detector_model.h5',
            'sugarcane_disease': 'saved_models/sugarcane_disease_detector_model.h5',
            'multitask': 'saved_models/multitask_model.h5',
            'best_model': 'saved_models/best_model.h5'
        }
        
        # Label paths configuration
        self.label_paths = {
            'crop_detector': 'model/crop_type_labels.txt',
            'corn_disease': 'model/corn_disease_labels.txt',
            'wheat_disease': 'model/wheat_disease_labels.txt',
            'rice_disease': 'model/rice_disease_labels.txt',
            'potato_disease': 'model/potato_disease_labels.txt',
            'sugarcane_disease': 'model/sugarcane_disease_labels.txt',
            'multitask': 'labels.txt',
            'best_model': 'labels.txt'
        }
        
        # Crop type to disease model mapping
        self.crop_to_disease_model = {
            'corn': 'corn_disease',
            'wheat': 'wheat_disease',
            'rice': 'rice_disease',
            'potato': 'potato_disease',
            'sugarcane': 'sugarcane_disease'
        }

    def initialize(self) -> bool:
        """Initialize all available models"""
        logger.info("🚀 Initializing Multi-Model Manager...")
        logger.info(f"📁 Working directory: {os.getcwd()}")
        logger.info(f"📁 Available files in current directory: {os.listdir('.')}")
        
        try:
            # Load crop detector first
            logger.info("🌾 Step 1: Loading crop detector model...")
            self._load_crop_detector()
            
            # Load disease-specific models
            logger.info("🦠 Step 2: Loading disease-specific models...")
            for crop_type in self.disease_models.keys():
                logger.info(f"   Loading {crop_type} disease model...")
                self._load_disease_model(crop_type)
            
            # Load fallback models
            logger.info("🔄 Step 3: Loading fallback models...")
            self._load_fallback_models()
            
            # Log final status
            self._log_final_status()
            
            self.is_initialized = True
            logger.info("✅ Multi-Model Manager initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize Multi-Model Manager: {e}")
            logger.error(f"❌ Exception type: {type(e).__name__}")
            import traceback
            logger.error(f"❌ Traceback: {traceback.format_exc()}")
            return False

    def _load_crop_detector(self):
        """Load the crop type detection model"""
        try:
            model_path = self.model_paths['crop_detector']
            logger.info(f"🔍 Checking crop detector at: {model_path}")
            logger.info(f"🔍 File exists: {os.path.exists(model_path)}")
            logger.info(f"🔍 Absolute path: {os.path.abspath(model_path)}")
            
            if os.path.exists(model_path):
                logger.info(f"📦 Loading crop detector from: {model_path}")
                self.crop_detector = tf.keras.models.load_model(model_path)
                logger.info(f"📝 Loading labels for crop detector...")
                self.model_labels['crop_detector'] = self._load_labels('crop_detector')
                self.model_status['crop_detector'] = 'loaded'
                logger.info(f"✅ Crop detector loaded successfully: {model_path}")
                logger.info(f"✅ Crop detector model type: {type(self.crop_detector)}")
                logger.info(f"✅ Crop detector labels count: {len(self.model_labels.get('crop_detector', []))}")
            else:
                logger.warning(f"⚠️ Crop detector not found: {model_path}")
                logger.warning(f"⚠️ Checked absolute path: {os.path.abspath(model_path)}")
                self.model_status['crop_detector'] = 'not_found'
        except Exception as e:
            logger.error(f"❌ Failed to load crop detector: {e}")
            logger.error(f"❌ Exception type: {type(e).__name__}")
            import traceback
            logger.error(f"❌ Traceback: {traceback.format_exc()}")
            self.model_status['crop_detector'] = 'error'

    def _load_disease_model(self, crop_type: str):
        """Load a disease-specific model for a crop type"""
        try:
            model_key = f"{crop_type}_disease"
            model_path = self.model_paths[model_key]
            logger.info(f"🔍 Checking {crop_type} disease model at: {model_path}")
            logger.info(f"🔍 File exists: {os.path.exists(model_path)}")
            logger.info(f"🔍 Absolute path: {os.path.abspath(model_path)}")
            
            if os.path.exists(model_path):
                logger.info(f"📦 Loading {crop_type} disease model from: {model_path}")
                self.disease_models[crop_type] = tf.keras.models.load_model(model_path)
                logger.info(f"📝 Loading labels for {crop_type} disease model...")
                self.model_labels[model_key] = self._load_labels(model_key)
                self.model_status[model_key] = 'loaded'
                logger.info(f"✅ {crop_type.title()} disease model loaded successfully: {model_path}")
                logger.info(f"✅ {crop_type} model type: {type(self.disease_models[crop_type])}")
                logger.info(f"✅ {crop_type} labels count: {len(self.model_labels.get(model_key, []))}")
            else:
                logger.warning(f"⚠️ {crop_type.title()} disease model not found: {model_path}")
                logger.warning(f"⚠️ Checked absolute path: {os.path.abspath(model_path)}")
                self.model_status[model_key] = 'not_found'
        except Exception as e:
            logger.error(f"❌ Failed to load {crop_type} disease model: {e}")
            logger.error(f"❌ Exception type: {type(e).__name__}")
            import traceback
            logger.error(f"❌ Traceback: {traceback.format_exc()}")
            self.model_status[model_key] = 'error'

    def _load_fallback_models(self):
        """Load fallback models for general disease detection"""
        fallback_order = ['multitask', 'best_model']
        logger.info(f"🔄 Attempting to load fallback models in order: {fallback_order}")
        
        for model_key in fallback_order:
            try:
                model_path = self.model_paths[model_key]
                logger.info(f"🔍 Checking fallback model {model_key} at: {model_path}")
                logger.info(f"🔍 File exists: {os.path.exists(model_path)}")
                logger.info(f"🔍 Absolute path: {os.path.abspath(model_path)}")
                
                if os.path.exists(model_path):
                    logger.info(f"📦 Loading fallback model {model_key} from: {model_path}")
                    model = tf.keras.models.load_model(model_path)
                    logger.info(f"📝 Loading labels for fallback model {model_key}...")
                    labels = self._load_labels(model_key)
                    self.fallback_models.append({
                        'model': model,
                        'name': model_key,
                        'labels': labels
                    })
                    self.model_status[model_key] = 'loaded'
                    logger.info(f"✅ Fallback model {model_key} loaded successfully")
                    logger.info(f"✅ {model_key} model type: {type(model)}")
                    logger.info(f"✅ {model_key} labels count: {len(labels)}")
                    break
                else:
                    logger.warning(f"⚠️ Fallback model {model_key} not found: {model_path}")
                    logger.warning(f"⚠️ Checked absolute path: {os.path.abspath(model_path)}")
                    self.model_status[model_key] = 'not_found'
            except Exception as e:
                logger.error(f"❌ Failed to load fallback model {model_key}: {e}")
                logger.error(f"❌ Exception type: {type(e).__name__}")
                import traceback
                logger.error(f"❌ Traceback: {traceback.format_exc()}")
                self.model_status[model_key] = 'error'

    def _load_labels(self, model_key: str) -> List[str]:
        """Load labels for a specific model"""
        try:
            label_path = self.label_paths[model_key]
            logger.info(f"🔍 Checking labels for {model_key} at: {label_path}")
            logger.info(f"🔍 Labels file exists: {os.path.exists(label_path)}")
            logger.info(f"🔍 Absolute path: {os.path.abspath(label_path)}")
            
            if os.path.exists(label_path):
                with open(label_path, 'r') as f:
                    labels = [line.strip() for line in f.readlines() if line.strip()]
                logger.info(f"📝 Loaded {len(labels)} labels for {model_key}")
                logger.info(f"📝 Labels: {labels[:5]}{'...' if len(labels) > 5 else ''}")
                return labels
            else:
                logger.warning(f"⚠️ Labels not found for {model_key}: {label_path}")
                logger.warning(f"⚠️ Checked absolute path: {os.path.abspath(label_path)}")
                return []
        except Exception as e:
            logger.error(f"❌ Failed to load labels for {model_key}: {e}")
            logger.error(f"❌ Exception type: {type(e).__name__}")
            import traceback
            logger.error(f"❌ Traceback: {traceback.format_exc()}")
            return []

    def _log_final_status(self):
        """Log the final status of all models after initialization"""
        logger.info("📊 === FINAL MODEL LOADING STATUS ===")
        
        # Crop detector status
        crop_status = self.model_status.get('crop_detector', 'not_loaded')
        logger.info(f"🌾 Crop Detector: {crop_status}")
        if crop_status == 'loaded':
            logger.info(f"   ✅ Model loaded: {type(self.crop_detector)}")
            logger.info(f"   ✅ Labels: {len(self.model_labels.get('crop_detector', []))} classes")
        
        # Disease models status
        logger.info("🦠 Disease Models:")
        for crop_type in self.disease_models.keys():
            model_key = f"{crop_type}_disease"
            status = self.model_status.get(model_key, 'not_loaded')
            logger.info(f"   {crop_type.title()}: {status}")
            if status == 'loaded':
                logger.info(f"     ✅ Model loaded: {type(self.disease_models[crop_type])}")
                logger.info(f"     ✅ Labels: {len(self.model_labels.get(model_key, []))} classes")
        
        # Fallback models status
        logger.info("🔄 Fallback Models:")
        for fallback in self.fallback_models:
            name = fallback['name']
            status = self.model_status.get(name, 'not_loaded')
            logger.info(f"   {name}: {status}")
            if status == 'loaded':
                logger.info(f"     ✅ Model loaded: {type(fallback['model'])}")
                logger.info(f"     ✅ Labels: {len(fallback['labels'])} classes")
        
        # Summary
        total_loaded = sum(1 for status in self.model_status.values() if status == 'loaded')
        total_models = len(self.model_status)
        logger.info(f"📈 Summary: {total_loaded}/{total_models} models loaded successfully")
        
        # List failed models
        failed_models = [name for name, status in self.model_status.items() if status == 'error']
        not_found_models = [name for name, status in self.model_status.items() if status == 'not_found']
        
        if failed_models:
            logger.warning(f"⚠️ Models with errors: {failed_models}")
        if not_found_models:
            logger.warning(f"⚠️ Models not found: {not_found_models}")
        
        logger.info("📊 === END MODEL LOADING STATUS ===")

    def analyze_crop_two_stage(self, image_data: Image.Image) -> Dict:
        """Two-stage analysis: crop detection + disease detection"""
        try:
            logger.info("🔍 Starting two-stage crop analysis...")
            
            # Stage 1: Crop type detection
            crop_type = self._detect_crop_type(image_data)
            logger.info(f"🌾 Detected crop type: {crop_type}")
            
            # Stage 2: Disease detection
            if crop_type and crop_type in self.disease_models:
                disease_result = self._detect_disease(image_data, crop_type)
                disease_result['crop_type_detected'] = crop_type
                disease_result['analysis_type'] = 'two_stage'
                return disease_result
            else:
                # Fallback to general disease detection
                logger.warning(f"⚠️ No specific model for {crop_type}, using fallback")
                return self._detect_disease_fallback(image_data, crop_type)
                
        except Exception as e:
            logger.error(f"❌ Two-stage analysis failed: {e}")
            return self._detect_disease_fallback(image_data, None)

    def analyze_crop_direct(self, image_data: Image.Image, crop_type: str = None) -> Dict:
        """Direct disease analysis with optional crop type specification"""
        try:
            logger.info(f"🔍 Starting direct disease analysis for crop: {crop_type}")
            
            if crop_type and crop_type in self.disease_models:
                return self._detect_disease(image_data, crop_type)
            else:
                return self._detect_disease_fallback(image_data, crop_type)
                
        except Exception as e:
            logger.error(f"❌ Direct analysis failed: {e}")
            return self._detect_disease_fallback(image_data, crop_type)

    def _detect_crop_type(self, image_data: Image.Image) -> Optional[str]:
        """Detect crop type using the crop detector model"""
        if not self.crop_detector:
            logger.warning("⚠️ Crop detector not available")
            return None
            
        try:
            # Preprocess image
            processed_image = self._preprocess_image(image_data)
            
            # Make prediction
            predictions = self.crop_detector.predict(processed_image, verbose=0)
            predicted_class_idx = np.argmax(predictions[0])
            confidence = np.max(predictions[0])
            
            # Get crop type
            crop_labels = self.model_labels.get('crop_detector', [])
            if predicted_class_idx < len(crop_labels):
                crop_type = crop_labels[predicted_class_idx].lower()
                logger.info(f"🌾 Crop type: {crop_type} (confidence: {confidence:.3f})")
                return crop_type
            else:
                logger.warning(f"⚠️ Invalid crop class index: {predicted_class_idx}")
                return None
                
        except Exception as e:
            logger.error(f"❌ Crop type detection failed: {e}")
            return None

    def _detect_disease(self, image_data: Image.Image, crop_type: str) -> Dict:
        """Detect diseases using crop-specific model"""
        disease_model = self.disease_models.get(crop_type)
        if not disease_model:
            logger.warning(f"⚠️ No disease model available for {crop_type}")
            return self._detect_disease_fallback(image_data, crop_type)
            
        try:
            # Preprocess image
            processed_image = self._preprocess_image(image_data)
            
            # Make prediction
            predictions = disease_model.predict(processed_image, verbose=0)
            predicted_class_idx = np.argmax(predictions[0])
            confidence = np.max(predictions[0])
            
            # Get disease label
            model_key = f"{crop_type}_disease"
            disease_labels = self.model_labels.get(model_key, [])
            if predicted_class_idx < len(disease_labels):
                disease_label = disease_labels[predicted_class_idx]
                is_healthy = 'healthy' in disease_label.lower()
                
                return {
                    'prediction_class': int(predicted_class_idx),
                    'crop_type': disease_label,
                    'confidence': float(confidence),
                    'is_healthy': is_healthy,
                    'all_predictions': predictions[0].tolist(),
                    'model_type': f'{crop_type}_specific',
                    'analysis_type': 'crop_specific'
                }
            else:
                logger.warning(f"⚠️ Invalid disease class index: {predicted_class_idx}")
                return self._detect_disease_fallback(image_data, crop_type)
                
        except Exception as e:
            logger.error(f"❌ Disease detection failed for {crop_type}: {e}")
            return self._detect_disease_fallback(image_data, crop_type)

    def _detect_disease_fallback(self, image_data: Image.Image, crop_type: str = None) -> Dict:
        """Fallback disease detection using general models"""
        for fallback in self.fallback_models:
            try:
                model = fallback['model']
                labels = fallback['labels']
                
                # Preprocess image
                processed_image = self._preprocess_image(image_data)
                
                # Make prediction
                predictions = model.predict(processed_image, verbose=0)
                predicted_class_idx = np.argmax(predictions[0])
                confidence = np.max(predictions[0])
                
                # Get disease label
                if predicted_class_idx < len(labels):
                    disease_label = labels[predicted_class_idx]
                    is_healthy = 'healthy' in disease_label.lower()
                    
                    return {
                        'prediction_class': int(predicted_class_idx),
                        'crop_type': disease_label,
                        'confidence': float(confidence),
                        'is_healthy': is_healthy,
                        'all_predictions': predictions[0].tolist(),
                        'model_type': fallback['name'],
                        'analysis_type': 'fallback',
                        'detected_crop_type': crop_type
                    }
                    
            except Exception as e:
                logger.error(f"❌ Fallback model {fallback['name']} failed: {e}")
                continue
        
        # If all fallbacks fail
        return {
            'prediction_class': -1,
            'crop_type': 'Unknown',
            'confidence': 0.0,
            'is_healthy': False,
            'all_predictions': [],
            'model_type': 'none',
            'analysis_type': 'failed',
            'error': 'All models failed'
        }

    def _preprocess_image(self, image_data: Image.Image) -> np.ndarray:
        """Preprocess image for model input"""
        try:
            # Convert to RGB if needed
            if image_data.mode != 'RGB':
                image_data = image_data.convert('RGB')
            
            # Resize to 224x224 (MobileNetV2 standard)
            image_data = image_data.resize((224, 224))
            
            # Convert to numpy array and normalize
            image_array = np.array(image_data) / 255.0
            
            # Add batch dimension
            image_array = np.expand_dims(image_array, axis=0)
            
            return image_array
            
        except Exception as e:
            logger.error(f"❌ Image preprocessing failed: {e}")
            raise

    def get_model_status(self) -> Dict:
        """Get status of all models"""
        return {
            'initialized': self.is_initialized,
            'crop_detector': self.model_status.get('crop_detector', 'not_loaded'),
            'disease_models': {
                crop: self.model_status.get(f"{crop}_disease", 'not_loaded')
                for crop in self.disease_models.keys()
            },
            'fallback_models': [
                {
                    'name': fallback['name'],
                    'status': self.model_status.get(fallback['name'], 'not_loaded')
                }
                for fallback in self.fallback_models
            ],
            'total_models_loaded': sum(1 for status in self.model_status.values() if status == 'loaded')
        }

    def get_available_crops(self) -> List[str]:
        """Get list of crops with available disease models"""
        return [
            crop for crop in self.disease_models.keys()
            if self.model_status.get(f"{crop}_disease") == 'loaded'
        ]

    def get_model_info(self, model_name: str) -> Dict:
        """Get detailed information about a specific model"""
        if model_name == 'crop_detector':
            return {
                'name': 'crop_detector',
                'type': 'crop_classification',
                'status': self.model_status.get('crop_detector', 'not_loaded'),
                'labels': self.model_labels.get('crop_detector', []),
                'num_classes': len(self.model_labels.get('crop_detector', []))
            }
        elif model_name in self.disease_models:
            model_key = f"{model_name}_disease"
            return {
                'name': model_key,
                'type': 'disease_classification',
                'crop_type': model_name,
                'status': self.model_status.get(model_key, 'not_loaded'),
                'labels': self.model_labels.get(model_key, []),
                'num_classes': len(self.model_labels.get(model_key, []))
            }
        else:
            return {'error': f'Model {model_name} not found'}

    def reload_model(self, model_name: str) -> bool:
        """Reload a specific model"""
        try:
            if model_name == 'crop_detector':
                self._load_crop_detector()
            elif model_name in self.disease_models:
                self._load_disease_model(model_name)
            else:
                logger.error(f"❌ Unknown model: {model_name}")
                return False
            return True
        except Exception as e:
            logger.error(f"❌ Failed to reload model {model_name}: {e}")
            return False

    def dispose(self):
        """Clean up resources"""
        logger.info("🧹 Disposing Multi-Model Manager...")
        self.crop_detector = None
        self.disease_models = {crop: None for crop in self.disease_models.keys()}
        self.fallback_models = []
        self.is_initialized = False
