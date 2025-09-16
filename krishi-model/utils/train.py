import os
import tensorflow as tf
from tensorflow.keras.callbacks import ModelCheckpoint, CSVLogger, EarlyStopping, ReduceLROnPlateau
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.models import Model
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization
from model.multitask_model import build_multitask_model # Keep for original model if needed

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
INITIAL_EPOCHS = 20 # Reduced for faster iteration, can be tuned
FINE_TUNE_EPOCHS = 30 # Reduced for faster iteration, can be tuned
TOTAL_EPOCHS = INITIAL_EPOCHS + FINE_TUNE_EPOCHS

def build_simple_classifier_model(num_classes, input_shape=(224, 224, 3)):
    """
    Builds a MobileNetV2-based classification model with a single output head.
    """
    base_model = MobileNetV2(input_shape=input_shape,
                             include_top=False,
                             weights='imagenet')

    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(256, activation='relu')(x)
    x = Dropout(0.5)(x)
    preds = Dense(num_classes, activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=preds)

    # Freeze the base model initially
    for layer in base_model.layers:
        layer.trainable = False
        
    return model, base_model

def train_model(train_gen, val_gen, num_classes):
    """
    Original multi-task model training function.
    """
    os.makedirs("logs", exist_ok=True)
    os.makedirs("saved_models", exist_ok=True)

    model = build_multitask_model(num_classes)

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
            'reg_output': 0.2  # reduce influence of regression
        }
    )

    # Callbacks
    checkpoint_cb = ModelCheckpoint(
        filepath='saved_models/best_model.keras',
        monitor='val_class_output_accuracy',
        save_best_only=True,
        mode='max',
        verbose=1
    )

    csv_logger = CSVLogger("logs/training_log.csv", append=True)

    early_stop = EarlyStopping(
        monitor='val_class_output_accuracy',
        patience=5,
        restore_best_weights=True,
        verbose=1
    )

    # Train
    history = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=25,
        callbacks=[checkpoint_cb, csv_logger, early_stop],
        verbose=1
    )

    return model, history

def train_crop_type_model(train_gen, val_gen, num_classes, epochs=TOTAL_EPOCHS, model_save_path='krishi-model/model/crop_type_model.h5'):
    """
    Trains a MobileNetV2 model for crop-type classification.
    """
    os.makedirs(os.path.dirname(model_save_path), exist_ok=True)
    os.makedirs("logs", exist_ok=True)

    model, base_model = build_simple_classifier_model(num_classes)

    # Initial training (feature extraction)
    model.compile(optimizer=Adam(learning_rate=1e-3),
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])

    early_stopping = EarlyStopping(monitor='val_loss', patience=7, restore_best_weights=True, verbose=1)
    reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, verbose=1)
    checkpoint = ModelCheckpoint(model_save_path, monitor='val_accuracy', save_best_only=True, mode='max', verbose=1)
    csv_logger = CSVLogger(os.path.join("logs", "crop_type_training_log.csv"), append=True)

    print("\n--- Starting initial training for Crop Type Model ---")
    history_initial = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=INITIAL_EPOCHS,
        callbacks=[early_stopping, reduce_lr, checkpoint, csv_logger],
        verbose=1
    )

    # Fine-tuning
    for layer in base_model.layers[-50:]: # Unfreeze last 50 layers
        layer.trainable = True

    model.compile(optimizer=Adam(learning_rate=1e-4), # Lower learning rate for fine-tuning
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])

    print("\n--- Starting fine-tuning for Crop Type Model ---")
    history_fine_tune = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=epochs,
        initial_epoch=history_initial.epoch[-1] + 1,
        callbacks=[early_stopping, reduce_lr, checkpoint, csv_logger],
        verbose=1
    )
    
    return model, history_initial, history_fine_tune

def train_disease_model(train_gen, val_gen, num_classes, crop_type, epochs=TOTAL_EPOCHS, model_save_path_base='krishi-model/model/'):
    """
    Trains a MobileNetV2 model for disease classification for a specific crop type.
    """
    model_save_path = os.path.join(model_save_path_base, f"{crop_type.lower()}_disease_model.h5")
    os.makedirs(os.path.dirname(model_save_path), exist_ok=True)
    os.makedirs("logs", exist_ok=True)

    model, base_model = build_simple_classifier_model(num_classes)

    # Initial training (feature extraction)
    model.compile(optimizer=Adam(learning_rate=1e-3),
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])

    early_stopping = EarlyStopping(monitor='val_loss', patience=7, restore_best_weights=True, verbose=1)
    reduce_lr = ReduceLROOnPlateau(monitor='val_loss', factor=0.5, patience=3, verbose=1)
    checkpoint = ModelCheckpoint(model_save_path, monitor='val_accuracy', save_best_only=True, mode='max', verbose=1)
    csv_logger = CSVLogger(os.path.join("logs", f"{crop_type.lower()}_disease_training_log.csv"), append=True)

    print(f"\n--- Starting initial training for {crop_type} Disease Model ---")
    history_initial = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=INITIAL_EPOCHS,
        callbacks=[early_stopping, reduce_lr, checkpoint, csv_logger],
        verbose=1
    )

    # Fine-tuning
    for layer in base_model.layers[-50:]: # Unfreeze last 50 layers
        layer.trainable = True

    model.compile(optimizer=Adam(learning_rate=1e-4), # Lower learning rate for fine-tuning
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])

    print(f"\n--- Starting fine-tuning for {crop_type} Disease Model ---")
    history_fine_tune = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=epochs,
        initial_epoch=history_initial.epoch[-1] + 1,
        callbacks=[early_stopping, reduce_lr, checkpoint, csv_logger],
        verbose=1
    )
    
    return model, history_initial, history_fine_tune

def train_multi_head_model(train_gen, val_gen, num_crop_types, num_disease_classes, epochs=TOTAL_EPOCHS, model_save_path='krishi-model/model/multi_head_model.h5'):
    """
    Trains a MobileNetV2-based multi-head model for crop type and disease classification.
    """
    os.makedirs(os.path.dirname(model_save_path), exist_ok=True)
    os.makedirs("logs", exist_ok=True)

    # Import build_multi_head_model here to avoid circular dependency if multitask_model imports train
    from model.multitask_model import build_multi_head_model
    model = build_multi_head_model(num_crop_types, num_disease_classes)

    # Freeze the base model initially (already done in build_multi_head_model, but re-iterate for clarity)
    for layer in model.layers:
        if isinstance(layer, tf.keras.Model) and layer.name == 'mobilenetv2': # Assuming base model name
            for base_layer in layer.layers:
                base_layer.trainable = False

    # Initial training (feature extraction)
    model.compile(
        optimizer=Adam(learning_rate=1e-3),
        loss={
            'crop_type_output': 'categorical_crossentropy',
            'disease_output': 'categorical_crossentropy'
        },
        metrics={
            'crop_type_output': 'accuracy',
            'disease_output': 'accuracy'
        },
        loss_weights={
            'crop_type_output': 1.0,
            'disease_output': 1.0
        }
    )

    early_stopping = EarlyStopping(monitor='val_loss', patience=7, restore_best_weights=True, verbose=1)
    reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, verbose=1)
    checkpoint = ModelCheckpoint(model_save_path, monitor='val_disease_output_accuracy', save_best_only=True, mode='max', verbose=1)
    csv_logger = CSVLogger(os.path.join("logs", "multi_head_training_log.csv"), append=True)

    print("\n--- Starting initial training for Multi-Head Model ---")
    history_initial = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=INITIAL_EPOCHS,
        callbacks=[early_stopping, reduce_lr, checkpoint, csv_logger],
        verbose=1
    )

    # Fine-tuning
    # Unfreeze the base model for fine-tuning
    for layer in model.layers:
        if isinstance(layer, tf.keras.Model) and layer.name == 'mobilenetv2':
            for base_layer in layer.layers[-50:]: # Unfreeze last 50 layers of base model
                base_layer.trainable = True

    model.compile(
        optimizer=Adam(learning_rate=1e-4), # Lower learning rate for fine-tuning
        loss={
            'crop_type_output': 'categorical_crossentropy',
            'disease_output': 'categorical_crossentropy'
        },
        metrics={
            'crop_type_output': 'accuracy',
            'disease_output': 'accuracy'
        },
        loss_weights={
            'crop_type_output': 1.0,
            'disease_output': 1.0
        }
    )

    print("\n--- Starting fine-tuning for Multi-Head Model ---")
    history_fine_tune = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=epochs,
        initial_epoch=history_initial.epoch[-1] + 1,
        callbacks=[early_stopping, reduce_lr, checkpoint, csv_logger],
        verbose=1
    )
    
    return model, history_initial, history_fine_tune