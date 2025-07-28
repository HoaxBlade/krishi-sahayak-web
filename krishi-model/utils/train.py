import os
from tensorflow.keras.callbacks import ModelCheckpoint, CSVLogger, EarlyStopping
from tensorflow.keras.optimizers import Adam
from model.multitask_model import build_multitask_model

def train_model(train_gen, val_gen, num_classes):
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