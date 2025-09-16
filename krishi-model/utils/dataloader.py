import os
import numpy as np
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.utils import to_categorical

def get_generators(data_dir, labels_path, img_size=(224, 224), batch_size=32):
    """
    Creates ImageDataGenerators for a single multi-class classification model.
    This is the original function, simplified to remove regression output.
    """
    with open(labels_path, 'r') as f:
        class_names = [line.strip() for line in f if line.strip()]
    num_classes = len(class_names)

    print(f"[INFO] Loaded {num_classes} classes from {labels_path}")

    train_datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        zoom_range=0.2,
        shear_range=0.2,
        horizontal_flip=True
    )

    val_datagen = ImageDataGenerator(rescale=1./255, validation_split=0.2)

    train_generator = train_datagen.flow_from_directory(
        data_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='training',
        classes=class_names # Ensure order of classes is consistent
    )

    val_generator = val_datagen.flow_from_directory(
        data_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='validation',
        classes=class_names # Ensure order of classes is consistent
    )
    
    return train_generator, val_generator, num_classes

def get_crop_type_generators(data_dir, labels_path, img_size=(224, 224), batch_size=32):
    """
    Creates ImageDataGenerators for the crop-type classification model.
    """
    with open(labels_path, 'r') as f:
        class_names = [line.strip() for line in f if line.strip()]
    num_classes = len(class_names)

    print(f"[INFO] Loaded {num_classes} crop types from {labels_path}")

    train_datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        zoom_range=0.2,
        shear_range=0.2,
        horizontal_flip=True
    )

    val_datagen = ImageDataGenerator(rescale=1./255, validation_split=0.2)

    train_generator = train_datagen.flow_from_directory(
        os.path.join(data_dir, 'train'),
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='training',
        classes=class_names
    )

    val_generator = val_datagen.flow_from_directory(
        os.path.join(data_dir, 'val'),
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='validation',
        classes=class_names
    )
    
    return train_generator, val_generator, num_classes

def get_disease_generators(data_dir, labels_path, img_size=(224, 224), batch_size=32):
    """
    Creates ImageDataGenerators for disease-specific classification models.
    `data_dir` should point to the crop-specific split data (e.g., 'krishi-model/SplitData_Disease_Specific/Corn').
    """
    with open(labels_path, 'r') as f:
        class_names = [line.strip() for line in f if line.strip()]
    num_classes = len(class_names)

    print(f"[INFO] Loaded {num_classes} disease labels from {labels_path}")

    train_datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        zoom_range=0.2,
        shear_range=0.2,
        horizontal_flip=True
    )

    val_datagen = ImageDataGenerator(rescale=1./255, validation_split=0.2)

    train_generator = train_datagen.flow_from_directory(
        os.path.join(data_dir, 'train'),
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='training',
        classes=class_names
    )

    val_generator = val_datagen.flow_from_directory(
        os.path.join(data_dir, 'val'),
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical',
        subset='validation',
        classes=class_names
    )
    
    return train_generator, val_generator, num_classes

def get_multi_head_generators(data_dir, original_labels_path, crop_type_labels_path, disease_labels_path, img_size=(224, 224), batch_size=32):
    """
    Creates ImageDataGenerators for a multi-head classification model,
    yielding images and two sets of categorical labels (crop type and disease type).
    """
    # Load all original labels
    with open(original_labels_path, 'r') as f:
        all_original_labels = [line.strip() for line in f if line.strip()]

    # Load crop type labels
    with open(crop_type_labels_path, 'r') as f:
        crop_type_names = [line.strip() for line in f if line.strip()]
    crop_type_indices = {name: i for i, name in enumerate(crop_type_names)}
    num_crop_types = len(crop_type_names)
    print(f"[INFO] Loaded {num_crop_types} crop types from {crop_type_labels_path}")

    # Load disease labels (all unique disease names across all crops)
    with open(disease_labels_path, 'r') as f:
        disease_names = [line.strip() for line in f if line.strip()]
    disease_indices = {name: i for i, name in enumerate(disease_names)}
    num_disease_classes = len(disease_names)
    print(f"[INFO] Loaded {num_disease_classes} disease labels from {disease_labels_path}")

    # Create a mapping from original full label to (crop_type_index, disease_index)
    label_to_multi_output_indices = {}
    for original_label in all_original_labels:
        # This logic needs to match how labels are parsed in prepare_hierarchical_data.py
        parts = original_label.replace('___', '_').split('_')
        crop_name = parts[0]
        disease_name = '_'.join(parts[1:]) if len(parts) > 1 else "Healthy" # Assuming "Healthy" if no disease part

        crop_idx = crop_type_indices.get(crop_name)
        disease_idx = disease_indices.get(disease_name)

        if crop_idx is None:
            print(f"[WARN] Crop type '{crop_name}' from original label '{original_label}' not found in crop_type_labels.txt. Skipping.")
            continue
        if disease_idx is None:
            print(f"[WARN] Disease name '{disease_name}' from original label '{original_label}' not found in disease_labels.txt. Skipping.")
            continue
        
        label_to_multi_output_indices[original_label] = (crop_idx, disease_idx)

    train_datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        zoom_range=0.2,
        shear_range=0.2,
        horizontal_flip=True
    )

    val_datagen = ImageDataGenerator(rescale=1./255, validation_split=0.2)

    # The flow_from_directory will still use the original full labels as class names
    # We will then map these to multi-head outputs in the custom generator
    train_flow = train_datagen.flow_from_directory(
        data_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical', # We need this to get the original class indices
        subset='training',
        classes=all_original_labels # Use all original labels as classes
    )

    val_flow = val_datagen.flow_from_directory(
        data_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode='categorical', # We need this to get the original class indices
        subset='validation',
        classes=all_original_labels # Use all original labels as classes
    )

    def multi_output_generator(flow):
        while True:
            x_batch, y_original_categorical = next(flow)
            
            y_crop_type_batch = []
            y_disease_batch = []

            # Map original categorical labels back to class names, then to multi-head indices
            # flow.class_indices maps class_name -> index
            # We need index -> class_name
            idx_to_class_name = {v: k for k, v in flow.class_indices.items()}

            for i in range(x_batch.shape[0]):
                original_class_idx = np.argmax(y_original_categorical[i])
                original_class_name = idx_to_class_name[original_class_idx]

                crop_idx, disease_idx = label_to_multi_output_indices.get(original_class_name, (None, None))

                if crop_idx is not None and disease_idx is not None:
                    y_crop_type_batch.append(to_categorical(crop_idx, num_classes=num_crop_types))
                    y_disease_batch.append(to_categorical(disease_idx, num_classes=num_disease_classes))
                else:
                    # Handle cases where mapping failed (should be caught by WARN above)
                    # For now, skip this sample or use a default/error label
                    # For training, it's better to ensure all labels are valid
                    pass # This should ideally not happen if data preparation is correct

            if not y_crop_type_batch or not y_disease_batch:
                continue # Skip if no valid samples in batch

            yield x_batch, {
                'crop_type_output': np.array(y_crop_type_batch),
                'disease_output': np.array(y_disease_batch)
            }

    return multi_output_generator(train_flow), multi_output_generator(val_flow), num_crop_types, num_disease_classes
