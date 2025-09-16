import os
import numpy as np
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.utils import to_categorical

def get_generators(data_dir, labels_path, img_size=(224, 224), batch_size=32):
    # 1. Read class names from label.txt
    with open(labels_path, 'r') as f:
        class_names = [line.strip() for line in f if line.strip()]
    class_indices = {cls: idx for idx, cls in enumerate(class_names)}
    num_classes = len(class_names)

    print(f"[INFO] Loaded {num_classes} classes from label.txt")
    print(f"[INFO] Class indices: {class_indices}")

    # 2. Preprocess label from class name
    def preprocess_label(class_name):
        if class_name not in class_indices:
            raise KeyError(f"[Label Error] Class '{class_name}' not found in label.txt!")
        class_idx = class_indices[class_name]
        y_class = to_categorical(class_idx, num_classes=num_classes)
        y_reg = np.array([100.0 if 'Healthy' in class_name else 60.0])
        return y_class, y_reg

    # 3. Data Augmentation
    datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        zoom_range=0.2,
        shear_range=0.2,
        horizontal_flip=True
    )

    # 4. Generator function
    def generator(subset):
        flow = datagen.flow_from_directory(
            data_dir,
            target_size=img_size,
            batch_size=batch_size,
            class_mode=None,
            shuffle=True,
            subset=subset
        )

        filenames = flow.filenames
        while True:
            x_batch = next(flow)
            start_idx = flow.batch_index * batch_size
            end_idx = start_idx + x_batch.shape[0]
            indices = flow.index_array[start_idx:end_idx]

            y_class_batch, y_reg_batch = [], []

            for i in indices:
                file_path = filenames[i]
                class_name = os.path.normpath(file_path).split(os.sep)[0]
                try:
                    y_c, y_r = preprocess_label(class_name)
                    y_class_batch.append(y_c)
                    y_reg_batch.append(y_r)
                except KeyError as e:
                    print(f"[WARN] Skipping file '{file_path}': {e}")
                    continue

            # Check for alignment
            if len(y_class_batch) != len(x_batch):
                continue  # skip incomplete batch

            yield x_batch, {
                'class_output': np.array(y_class_batch),
                'reg_output': np.array(y_reg_batch)
            }

    return generator('training'), generator('validation'), num_classes
