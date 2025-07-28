import os
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.utils import to_categorical
import numpy as np

def get_generators(data_dir, labels_path, img_size=(224, 224), batch_size=32):
    with open(labels_path, 'r') as f:
        class_names = [line.strip() for line in f]

    class_indices = {cls: idx for idx, cls in enumerate(class_names)}

    def preprocess_label(class_name):
        class_idx = class_indices[class_name]
        y_class = to_categorical(class_idx, num_classes=len(class_names))
        y_reg = np.array([100.0 if 'Healthy' in class_name else 60.0])  # naive health score rule
        return y_class, y_reg

    datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        zoom_range=0.2,
        shear_range=0.2,
        horizontal_flip=True
    )

    def generator(subset):
        flow = datagen.flow_from_directory(
            data_dir,
            target_size=img_size,
            batch_size=batch_size,
            class_mode=None,
            shuffle=True,
            subset=subset
        )

        while True:
            x_batch = next(flow)
            y_class_batch, y_reg_batch = [], []

            for path in flow.filenames:
                class_name = path.split('/')[0]
                y_c, y_r = preprocess_label(class_name)
                y_class_batch.append(y_c)
                y_reg_batch.append(y_r)

            yield x_batch, {
                'class_output': np.array(y_class_batch),
                'reg_output': np.array(y_reg_batch)
            }

    return generator('training'), generator('validation'), len(class_names)