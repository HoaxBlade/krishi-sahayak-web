from tensorflow.keras.callbacks import ModelCheckpoint
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.models import load_model
from model.multitask_model import build_multitask_model

def train_model(train_gen, val_gen, num_classes):
    model = build_multitask_model(num_classes)

    model.compile(
        optimizer=Adam(1e-4),
        loss={
            'class_output': 'categorical_crossentropy',
            'reg_output': 'mse'
        },
        metrics={
            'class_output': 'accuracy',
            'reg_output': 'mae'
        }
    )

    checkpoint_cb = ModelCheckpoint(
        filepath='saved_models/best_model.keras',
        monitor='val_class_output_accuracy',
        save_best_only=True,
        mode='max',
        verbose=1
    )

    history = model.fit(
        train_gen,
        validation_data=val_gen,
        epochs=25,
        callbacks=[checkpoint_cb]
    )
    return model, history