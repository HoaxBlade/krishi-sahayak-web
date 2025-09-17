import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from data_utils import get_crop_labels, create_image_generators, IMAGE_SIZE, BATCH_SIZE, DATA_DIR

# Define constants
EPOCHS_HEAD = 20
EPOCHS_FINE_TUNE = 80
FINE_TUNE_AT = 100 # Unfreeze layers from this point onwards
MODEL_SAVE_PATH = 'krishi-model/saved_models/crop_detector_model.h5'
LABELS_PATH = 'krishi-model/model/crop_type_labels.txt'

def create_model(num_classes):
    """Creates a pre-trained MobileNetV2 model with a new classification head."""
    inputs = tf.keras.layers.Input(shape=(IMAGE_SIZE[0], IMAGE_SIZE[1], 3))
    base_model = MobileNetV2(input_tensor=inputs,
                             include_top=False,
                             weights='imagenet')

    # Freeze the base model
    base_model.trainable = False

    # Add a new classification head
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(512, activation='relu')(x)
    predictions = Dense(num_classes, activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=predictions)
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    return model, base_model

def fine_tune_model(model, base_model, num_classes):
    """Fine-tunes the model by unfreezing some layers of the base model."""
    # Unfreeze all layers of the base model
    base_model.trainable = True

    # Freeze all layers before the `FINE_TUNE_AT` layer
    for layer in base_model.layers[:FINE_TUNE_AT]:
        layer.trainable = False

    model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])
    return model

def train_crop_detector():
    """Trains the base model to detect crop types with pre-training, early stopping, and fine-tuning."""
    crop_labels = get_crop_labels(DATA_DIR)
    num_classes = len(crop_labels)

    if not os.path.exists(os.path.dirname(MODEL_SAVE_PATH)):
        os.makedirs(os.path.dirname(MODEL_SAVE_PATH))

    # Save crop labels
    with open(LABELS_PATH, 'w') as f:
        for label in crop_labels:
            f.write(f"{label}\n")
    print(f"Crop labels saved to {LABELS_PATH}")

    train_datagen, val_datagen, test_datagen = create_image_generators(IMAGE_SIZE, BATCH_SIZE)

    train_generator = train_datagen.flow_from_directory(
        os.path.join(DATA_DIR, 'train'),
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        classes=crop_labels
    )
    val_generator = val_datagen.flow_from_directory(
        os.path.join(DATA_DIR, 'val'),
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        classes=crop_labels
    )
    test_generator = test_datagen.flow_from_directory(
        os.path.join(DATA_DIR, 'test'),
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        classes=crop_labels
    )

    model, base_model = create_model(num_classes)
    model.summary()

    # Callbacks
    early_stopping = EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True)
    model_checkpoint = ModelCheckpoint(MODEL_SAVE_PATH, save_best_only=True, monitor='val_loss', mode='min')
    reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=2, min_lr=1e-7, verbose=1)

    print("\nTraining classification head...")
    history_head = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // BATCH_SIZE,
        epochs=EPOCHS_HEAD,
        validation_data=val_generator,
        validation_steps=val_generator.samples // BATCH_SIZE,
        callbacks=[early_stopping, model_checkpoint, reduce_lr]
    )

    print("\nFine-tuning the model...")
    model = fine_tune_model(model, base_model, num_classes)
    model.summary()

    history_fine_tune = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // BATCH_SIZE,
        epochs=EPOCHS_HEAD + EPOCHS_FINE_TUNE, # Total epochs
        initial_epoch=history_head.epoch[-1], # Start from where head training left off
        validation_data=val_generator,
        validation_steps=val_generator.samples // BATCH_SIZE,
        callbacks=[early_stopping, model_checkpoint, reduce_lr]
    )

    print(f"Crop detector model saved to {MODEL_SAVE_PATH}")

    # Evaluate the model
    print("\nEvaluating crop detector model on test data...")
    loss, accuracy = model.evaluate(test_generator)
    print(f"Test Loss: {loss:.4f}")
    print(f"Test Accuracy: {accuracy:.4f}")

if __name__ == '__main__':
    train_crop_detector()