#!/usr/bin/env python3
"""
Convert all Keras models to TensorFlow Lite format for mobile deployment
"""

import os
import sys
import tensorflow as tf
from pathlib import Path

def convert_model_to_tflite(model_path: str, output_path: str, model_name: str) -> bool:
    """Convert a single Keras model to TFLite format"""
    try:
        print(f"🔄 Converting {model_name}...")
        
        # Load the Keras model
        model = tf.keras.models.load_model(model_path)
        print(f"✅ Loaded {model_name} from {model_path}")
        
        # Create TFLite converter
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # Add optimizations for mobile deployment
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        
        # Convert to TFLite
        tflite_model = converter.convert()
        
        # Save TFLite model
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        # Get file sizes
        keras_size = os.path.getsize(model_path) / (1024 * 1024)  # MB
        tflite_size = os.path.getsize(output_path) / (1024 * 1024)  # MB
        compression_ratio = (1 - tflite_size / keras_size) * 100
        
        print(f"✅ {model_name} converted successfully!")
        print(f"📊 Keras size: {keras_size:.2f} MB")
        print(f"📊 TFLite size: {tflite_size:.2f} MB")
        print(f"📊 Compression: {compression_ratio:.1f}%")
        print(f"📁 Saved to: {output_path}")
        print("-" * 50)
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to convert {model_name}: {e}")
        return False

def convert_all_models():
    """Convert all Keras models to TFLite format"""
    print("🚀 Starting conversion of all models to TFLite format...")
    print("=" * 60)
    
    # Define model configurations
    models = [
        {
            'name': 'crop_detector',
            'keras_path': 'saved_models/crop_detector_model.h5',
            'tflite_path': 'saved_models/crop_detector_model.tflite'
        },
        {
            'name': 'corn_disease_detector',
            'keras_path': 'saved_models/corn_disease_detector_model.h5',
            'tflite_path': 'saved_models/corn_disease_detector_model.tflite'
        },
        {
            'name': 'wheat_disease_detector',
            'keras_path': 'saved_models/wheat_disease_detector_model.h5',
            'tflite_path': 'saved_models/wheat_disease_detector_model.tflite'
        },
        {
            'name': 'rice_disease_detector',
            'keras_path': 'saved_models/rice_disease_detector_model.h5',
            'tflite_path': 'saved_models/rice_disease_detector_model.tflite'
        },
        {
            'name': 'potato_disease_detector',
            'keras_path': 'saved_models/potato_disease_detector_model.h5',
            'tflite_path': 'saved_models/potato_disease_detector_model.tflite'
        },
        {
            'name': 'sugarcane_disease_detector',
            'keras_path': 'saved_models/sugarcane_disease_detector_model.h5',
            'tflite_path': 'saved_models/sugarcane_disease_detector_model.tflite'
        },
        {
            'name': 'multitask_model',
            'keras_path': 'saved_models/multitask_model.h5',
            'tflite_path': 'saved_models/multitask_model.tflite'
        },
        {
            'name': 'best_model',
            'keras_path': 'saved_models/best_model.h5',
            'tflite_path': 'saved_models/best_model.tflite'
        }
    ]
    
    # Create output directory if it doesn't exist
    os.makedirs('saved_models', exist_ok=True)
    
    # Track conversion results
    successful_conversions = 0
    failed_conversions = 0
    
    # Convert each model
    for model_config in models:
        keras_path = model_config['keras_path']
        tflite_path = model_config['tflite_path']
        model_name = model_config['name']
        
        # Check if Keras model exists
        if not os.path.exists(keras_path):
            print(f"⚠️ Keras model not found: {keras_path}")
            failed_conversions += 1
            continue
        
        # Convert model
        if convert_model_to_tflite(keras_path, tflite_path, model_name):
            successful_conversions += 1
        else:
            failed_conversions += 1
    
    # Print summary
    print("\n" + "=" * 60)
    print("📊 CONVERSION SUMMARY")
    print("=" * 60)
    print(f"✅ Successful conversions: {successful_conversions}")
    print(f"❌ Failed conversions: {failed_conversions}")
    print(f"📊 Total models processed: {len(models)}")
    
    if successful_conversions > 0:
        print("\n🎉 TFLite models are ready for mobile deployment!")
        print("📁 All TFLite models saved in: saved_models/")
        
        # List converted models
        print("\n📋 Converted TFLite models:")
        for model_config in models:
            tflite_path = model_config['tflite_path']
            if os.path.exists(tflite_path):
                size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
                print(f"  - {model_config['name']}: {size_mb:.2f} MB")
    
    return successful_conversions > 0

def create_model_bundle():
    """Create a model bundle with all TFLite models for Flutter app"""
    print("\n📦 Creating model bundle for Flutter app...")
    
    # Create assets directory structure
    assets_dir = Path("../krishi_app/assets/models")
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy TFLite models to Flutter assets
    models_to_copy = [
        ('saved_models/crop_detector_model.tflite', 'crop_detector_model.tflite'),
        ('saved_models/multitask_model.tflite', 'multitask_crop_health_model.tflite'),
        ('saved_models/best_model.tflite', 'crop_health_model.tflite'),
        ('saved_models/corn_disease_detector_model.tflite', 'corn_disease_model.tflite'),
        ('saved_models/wheat_disease_detector_model.tflite', 'wheat_disease_model.tflite'),
        ('saved_models/rice_disease_detector_model.tflite', 'rice_disease_model.tflite'),
        ('saved_models/potato_disease_detector_model.tflite', 'potato_disease_model.tflite'),
        ('saved_models/sugarcane_disease_detector_model.tflite', 'sugarcane_disease_model.tflite')
    ]
    
    copied_models = 0
    for src_path, dst_name in models_to_copy:
        if os.path.exists(src_path):
            dst_path = assets_dir / dst_name
            try:
                import shutil
                shutil.copy2(src_path, dst_path)
                size_mb = os.path.getsize(dst_path) / (1024 * 1024)
                print(f"✅ Copied {dst_name} ({size_mb:.2f} MB)")
                copied_models += 1
            except Exception as e:
                print(f"❌ Failed to copy {dst_name}: {e}")
        else:
            print(f"⚠️ Source model not found: {src_path}")
    
    print(f"\n📦 Model bundle created: {copied_models} models copied to Flutter assets")
    return copied_models > 0

if __name__ == "__main__":
    print("🌾 Krishi Sahayak Model Conversion to TFLite")
    print("=" * 60)
    
    try:
        # Convert all models
        if convert_all_models():
            print("\n🎯 Creating model bundle for Flutter app...")
            if create_model_bundle():
                print("\n🎉 All models converted and bundled successfully!")
                print("You can now use the TFLite models in your Flutter app.")
            else:
                print("\n⚠️ Models converted but bundle creation failed.")
        else:
            print("\n💥 Model conversion failed!")
            sys.exit(1)
    except Exception as e:
        print(f"\n💥 Conversion process failed: {e}")
        sys.exit(1)
