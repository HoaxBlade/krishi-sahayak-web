#!/usr/bin/env python3
"""
Convert existing single-task model to multitask model
This script takes the existing best_model.h5 and adds a regression head
"""

import os
import sys
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, Lambda
from tensorflow.keras.regularizers import l2

def convert_to_multitask():
    """Convert existing single-task model to multitask model"""
    print("🔄 Converting existing model to multitask...")
    
    # Load the existing model
    model_path = 'saved_models/best_model.h5'
    if not os.path.exists(model_path):
        print(f"❌ Model not found at {model_path}")
        return False
    
    print(f"📥 Loading existing model from {model_path}...")
    try:
        # Load the model
        base_model = tf.keras.models.load_model(model_path)
        print(f"✅ Model loaded successfully")
        print(f"📊 Model input shape: {base_model.input_shape}")
        print(f"📊 Model output shape: {base_model.output_shape}")
        
        # Get the last layer before the output (assuming it's a Dense layer)
        # We need to remove the last layer and add our multitask heads
        if len(base_model.layers) < 2:
            print("❌ Model doesn't have enough layers for conversion")
            return False
        
        # Get the second-to-last layer (before the final classification layer)
        last_hidden_layer = base_model.layers[-2]
        print(f"📊 Last hidden layer: {last_hidden_layer.name}, output shape: {last_hidden_layer.output_shape}")
        
        # Create new model with multitask heads
        print("🏗️ Creating multitask model...")
        
        # Get the input
        model_input = base_model.input
        
        # Get the features from the last hidden layer
        features = last_hidden_layer.output
        
        # Add classification head (same as original)
        class_output = Dense(
            17,  # 17 classes
            activation='softmax',
            name='class_output',
            kernel_regularizer=l2(0.001)
        )(features)
        
        # Add regression head for confidence scoring
        reg_output_raw = Dense(
            1,
            activation='sigmoid',
            kernel_regularizer=l2(0.001)
        )(features)
        
        # Scale to 0-100 range
        reg_output = Lambda(lambda t: t * 100, name='reg_output')(reg_output_raw)
        
        # Create the multitask model
        multitask_model = Model(
            inputs=model_input,
            outputs={'class_output': class_output, 'reg_output': reg_output}
        )
        
        print("✅ Multitask model created successfully")
        print(f"📊 Model outputs: {multitask_model.output_names}")
        
        # Copy weights from the original model
        print("🔄 Copying weights from original model...")
        
        # Copy weights for all layers except the last one
        for i, layer in enumerate(multitask_model.layers):
            if i < len(base_model.layers) - 1:  # All layers except the last
                if hasattr(layer, 'set_weights') and hasattr(base_model.layers[i], 'get_weights'):
                    try:
                        layer.set_weights(base_model.layers[i].get_weights())
                        print(f"✅ Copied weights for layer {i}: {layer.name}")
                    except Exception as e:
                        print(f"⚠️ Could not copy weights for layer {i}: {e}")
        
        # Initialize regression head with small random weights
        print("🔄 Initializing regression head...")
        reg_layer = multitask_model.get_layer('reg_output')
        reg_layer.set_weights([
            np.random.normal(0, 0.01, reg_layer.get_weights()[0].shape),
            np.random.normal(0, 0.01, reg_layer.get_weights()[1].shape)
        ])
        
        # Compile the model
        print("⚙️ Compiling multitask model...")
        multitask_model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
            loss={
                'class_output': 'categorical_crossentropy',
                'reg_output': 'mse'
            },
            metrics={
                'class_output': 'accuracy',
                'reg_output': 'mae'
            },
            loss_weights={
                'class_output': 1.0,
                'reg_output': 0.2  # Reduce influence of regression
            }
        )
        
        # Print model summary
        print("📋 Multitask Model Summary:")
        multitask_model.summary()
        
        # Save the multitask model
        multitask_path = 'saved_models/multitask_model.h5'
        print(f"💾 Saving multitask model to {multitask_path}...")
        multitask_model.save(multitask_path)
        
        # Get file size
        file_size = os.path.getsize(multitask_path) / (1024 * 1024)  # MB
        print(f"✅ Multitask model saved successfully!")
        print(f"📁 Path: {multitask_path}")
        print(f"📊 Size: {file_size:.2f} MB")
        
        # Test the model
        print("🧪 Testing multitask model...")
        test_input = np.random.random((1, 224, 224, 3)).astype(np.float32)
        predictions = multitask_model.predict(test_input, verbose=0)
        
        print(f"📊 Class output shape: {predictions['class_output'].shape}")
        print(f"📊 Regression output shape: {predictions['reg_output'].shape}")
        print(f"📊 Class output sample: {predictions['class_output'][0][:5]}...")
        print(f"📊 Regression output sample: {predictions['reg_output'][0]}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        return False

def convert_to_tflite():
    """Convert the multitask model to TFLite format"""
    try:
        print("🔄 Converting multitask model to TFLite...")
        
        # Load the multitask model
        model_path = 'saved_models/multitask_model.h5'
        if not os.path.exists(model_path):
            print(f"❌ Multitask model not found at {model_path}")
            return False
        
        print(f"📥 Loading multitask model from {model_path}...")
        model = tf.keras.models.load_model(model_path)
        
        # Create TFLite converter
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        
        # Add optimizations for mobile
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS
        ]
        
        # Convert
        print("🔄 Converting to TFLite...")
        tflite_model = converter.convert()
        
        # Save TFLite model
        tflite_path = 'saved_models/multitask_model.tflite'
        with open(tflite_path, 'wb') as f:
            f.write(tflite_model)
        
        # Get file size
        file_size = os.path.getsize(tflite_path) / (1024 * 1024)  # MB
        print(f"✅ TFLite conversion successful!")
        print(f"📁 TFLite model saved to: {tflite_path}")
        print(f"📊 Size: {file_size:.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"❌ Error converting to TFLite: {e}")
        return False

if __name__ == "__main__":
    print("🌾 Krishi Sahayak Model Conversion to Multitask")
    print("=" * 60)
    
    try:
        # Convert to multitask
        if convert_to_multitask():
            print("\n🎯 Converting to TFLite...")
            if convert_to_tflite():
                print("\n🎉 Multitask model conversion completed successfully!")
                print("You can now use the model in your server and Flutter app.")
            else:
                print("\n⚠️ Multitask model created but TFLite conversion failed.")
        else:
            print("\n💥 Model conversion failed!")
            sys.exit(1)
    except Exception as e:
        print(f"\n💥 Conversion failed: {e}")
        sys.exit(1)
