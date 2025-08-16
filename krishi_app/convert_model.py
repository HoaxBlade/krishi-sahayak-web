#!/usr/bin/env python3
"""
Convert best_model.h5 to TFLite for Flutter app
This script converts the Keras model to TFLite format
"""

import tensorflow as tf
import os
import sys

def convert_h5_to_tflite():
    print("🔄 Converting best_model.h5 to TFLite...")
    
    # Paths
    h5_model_path = "../krishi-model/notebooks/model/best_model.h5"
    tflite_output_path = "assets/models/crop_health_model.tflite"
    
    # Check if input model exists
    if not os.path.exists(h5_model_path):
        print(f"❌ Error: Model not found at {h5_model_path}")
        print("Please make sure the path is correct")
        return False
    
    try:
        # Load the Keras model
        print("📥 Loading Keras model...")
        model = tf.keras.models.load_model(h5_model_path)
        print(f"✅ Model loaded successfully")
        print(f"📊 Model summary:")
        model.summary()
        
        # Create TFLite converter
        print("🔄 Creating TFLite converter...")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # Optional: Add optimizations for mobile
        print("⚡ Adding mobile optimizations...")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        
        # Optional: Set target specs for mobile
        converter.target_spec.supported_types = [tf.float16]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        
        # Convert the model
        print("🔄 Converting to TFLite...")
        tflite_model = converter.convert()
        
        # Save the TFLite model
        print(f"💾 Saving TFLite model to {tflite_output_path}...")
        os.makedirs(os.path.dirname(tflite_output_path), exist_ok=True)
        
        with open(tflite_output_path, 'wb') as f:
            f.write(tflite_model)
        
        # Get file size
        file_size = os.path.getsize(tflite_output_path) / (1024 * 1024)  # MB
        print(f"✅ Conversion successful!")
        print(f"📁 Output: {tflite_output_path}")
        print(f"📊 Size: {file_size:.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        return False

if __name__ == "__main__":
    success = convert_h5_to_tflite()
    if success:
        print("\n🎉 Model conversion completed successfully!")
        print("You can now use the TFLite model in your Flutter app.")
    else:
        print("\n💥 Model conversion failed!")
        sys.exit(1)
