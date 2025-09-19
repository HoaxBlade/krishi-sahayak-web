#!/usr/bin/env python3
"""
Convert multitask model to TFLite for Flutter app
This script converts the multitask Keras model to TFLite format
"""

import tensorflow as tf
import os
import sys

def convert_multitask_to_tflite():
    print("🔄 Converting multitask model to TFLite...")
    
    # Paths
    h5_model_path = "../krishi-model/saved_models/multitask_model.h5"
    tflite_output_path = "assets/models/multitask_crop_health_model.tflite"
    
    # Check if input model exists
    if not os.path.exists(h5_model_path):
        print(f"❌ Error: Multitask model not found at {h5_model_path}")
        print("Please make sure the model is trained and saved first.")
        return False
    
    try:
        # Load the Keras model
        print("📥 Loading multitask Keras model...")
        model = tf.keras.models.load_model(h5_model_path)
        print(f"✅ Model loaded successfully")
        print(f"📊 Model outputs: {model.output_names}")
        print(f"📊 Model input shape: {model.input_shape}")
        
        # Verify it's a multitask model
        if len(model.output_names) != 2:
            print(f"❌ Error: Expected 2 outputs, got {len(model.output_names)}")
            print(f"Output names: {model.output_names}")
            return False
        
        print(f"✅ Multitask model confirmed: {model.output_names}")
        
        # Create TFLite converter
        print("🔄 Creating TFLite converter...")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # Add optimizations for mobile
        print("⚡ Adding mobile optimizations...")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
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
        
        # Test the converted model
        print("🧪 Testing converted model...")
        test_tflite_model(tflite_output_path)
        
        return True
        
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        return False

def test_tflite_model(tflite_path):
    """Test the converted TFLite model"""
    try:
        # Load TFLite model
        interpreter = tf.lite.Interpreter(model_path=tflite_path)
        interpreter.allocate_tensors()
        
        # Get input and output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"📊 Input details: {input_details[0]}")
        print(f"📊 Output details: {len(output_details)} outputs")
        for i, output in enumerate(output_details):
            print(f"  Output {i}: {output}")
        
        # Test with dummy input
        input_shape = input_details[0]['shape']
        dummy_input = tf.random.normal(input_shape, dtype=tf.float32)
        
        interpreter.set_tensor(input_details[0]['index'], dummy_input)
        interpreter.invoke()
        
        # Get outputs
        class_output = interpreter.get_tensor(output_details[0]['index'])
        reg_output = interpreter.get_tensor(output_details[1]['index'])
        
        print(f"✅ Model test successful!")
        print(f"📊 Class output shape: {class_output.shape}")
        print(f"📊 Regression output shape: {reg_output.shape}")
        print(f"📊 Class output sample: {class_output[0][:5]}...")
        print(f"📊 Regression output sample: {reg_output[0]}")
        
    except Exception as e:
        print(f"❌ Error testing TFLite model: {e}")

if __name__ == "__main__":
    success = convert_multitask_to_tflite()
    if success:
        print("\n🎉 Multitask model conversion completed successfully!")
        print("You can now use the TFLite model in your Flutter app.")
    else:
        print("\n💥 Model conversion failed!")
        sys.exit(1)
