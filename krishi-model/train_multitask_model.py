#!/usr/bin/env python3
"""
Train and save multitask model for Krishi Sahayak
This script trains a multitask model with classification and regression heads
"""

import os
import sys
import numpy as np
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
import tensorflow as tf

# Add the model directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'model'))

from multitask_model import build_multitask_model
from utils.dataloader import get_generators
from config import IMAGE_SIZE

def train_multitask_model():
    """Train the multitask model and save it"""
    print("🚀 Starting multitask model training...")
    
    # Create directories
    os.makedirs("saved_models", exist_ok=True)
    os.makedirs("logs", exist_ok=True)
    
    # Load data
    print("📊 Loading training data...")
    train_gen, val_gen = get_generators()
    num_classes = 17  # Based on your labels
    
    # Build model
    print("🏗️ Building multitask model...")
    model = build_multitask_model(num_classes)
    
    # Compile model
    print("⚙️ Compiling model...")
    model.compile(
        optimizer=Adam(learning_rate=1e-4),
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
    print("📋 Model Summary:")
    model.summary()
    
    # Callbacks
    callbacks = [
        ModelCheckpoint(
            filepath='saved_models/multitask_model.h5',
            monitor='val_class_output_accuracy',
            save_best_only=True,
            mode='max',
            verbose=1
        ),
        EarlyStopping(
            monitor='val_class_output_accuracy',
            patience=10,
            restore_best_weights=True,
            verbose=1
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-7,
            verbose=1
        )
    ]
    
    # Train model
    print("🎯 Starting training...")
    history = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=50,
        callbacks=callbacks,
        verbose=1
    )
    
    print("✅ Training completed!")
    print(f"📁 Model saved to: saved_models/multitask_model.h5")
    
    # Convert to TFLite
    print("🔄 Converting to TFLite...")
    convert_to_tflite()
    
    return model

def convert_to_tflite():
    """Convert the trained multitask model to TFLite format"""
    try:
        # Load the trained model
        model_path = 'saved_models/multitask_model.h5'
        if not os.path.exists(model_path):
            print(f"❌ Model not found at {model_path}")
            return False
        
        print(f"📥 Loading model from {model_path}...")
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
    print("🌾 Krishi Sahayak Multitask Model Training")
    print("=" * 50)
    
    # Check if data directory exists
    if not os.path.exists("Data"):
        print("❌ Training data directory 'Data' not found!")
        print("Please ensure training data is available.")
        sys.exit(1)
    
    try:
        model = train_multitask_model()
        print("\n🎉 Multitask model training and conversion completed successfully!")
        print("You can now use the model in your server and Flutter app.")
    except Exception as e:
        print(f"\n💥 Training failed: {e}")
        sys.exit(1)
