import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator

IMAGE_SIZE = (128, 128)
BATCH_SIZE = 32
DEFAULT_DATA_DIR = 'krishi-model/SplitData'
CROP_LABELS_FILE = 'krishi-model/model/crop_type_labels.txt'

def get_crop_labels():
    """Reads crop types from a predefined labels file."""
    if not os.path.exists(CROP_LABELS_FILE):
        print(f"Warning: Crop labels file not found at {CROP_LABELS_FILE}. Falling back to directory scanning.")
        return _get_crop_labels_from_dirs(DEFAULT_DATA_DIR) # Fallback to old method

    with open(CROP_LABELS_FILE, 'r') as f:
        crop_types = [line.strip() for line in f if line.strip()]
    return sorted(list(set(crop_types)))

def _get_crop_labels_from_dirs(data_dir):
    """Helper function to extract unique crop types from the dataset directory names."""
    crop_types = set()
    for split in ['train', 'val', 'test']:
        split_path = os.path.join(data_dir, split)
        if os.path.exists(split_path):
            for class_name in os.listdir(split_path):
                crop_type = class_name.split('___')[0]
                crop_types.add(crop_type)
    return sorted(list(crop_types))

def get_disease_labels_for_crop(crop_type, data_dir=DEFAULT_DATA_DIR):
    """Extracts disease labels for a specific crop type."""
    disease_labels = set()
    for split in ['train', 'val', 'test']:
        split_path = os.path.join(data_dir, split)
        if os.path.exists(split_path):
            for class_name in os.listdir(split_path):
                if class_name.startswith(f"{crop_type}___") or class_name.startswith(f"{crop_type}_"):
                    disease_labels.add(class_name)
    return sorted(list(disease_labels))

def create_image_generators(image_size=IMAGE_SIZE, batch_size=BATCH_SIZE):
    """Creates and returns ImageDataGenerator instances for training, validation, and testing."""
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest'
    )
    val_test_datagen = ImageDataGenerator(rescale=1./255)
    return train_datagen, val_test_datagen, val_test_datagen

def create_data_generators(
    data_dir=DEFAULT_DATA_DIR,
    target_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    classes=None, # List of class names to include
    subset_for_crop_detector=False # Special handling for crop detector
):
    """
    Creates data generators for train, validation, and test sets.
    If subset_for_crop_detector is True, it will map full labels to crop types.
    """
    train_datagen, val_datagen, test_datagen = create_image_generators(target_size, batch_size)

    if subset_for_crop_detector:
        # For crop detector, we need to map all disease labels to their respective crop types
        # This requires a custom flow_from_directory or a more complex approach.
        # For simplicity, we'll assume flow_from_directory can handle mapping if 'classes' are just crop types.
        # However, flow_from_directory expects directories to match 'classes' exactly.
        # A more robust solution would involve creating symbolic links or a custom data loader.
        # For now, we'll rely on the 'classes' parameter to filter, which means the directories
        # must be named as crop types, which is not the case in SplitData.
        # The train_crop_detector.py script handles this by extracting crop types from full labels.
        # This utility function will be more suited for disease-specific models.
        print("Warning: `subset_for_crop_detector` is not fully implemented for direct crop type mapping via flow_from_directory.")
        print("Please ensure your directory structure or custom logic aligns with `classes` for crop detection.")
        # Fallback to generic flow_from_directory, assuming 'classes' are the actual directory names
        # This part needs careful consideration if the directory structure is not flat for crop types.
        # The current `train_crop_detector.py` directly uses `crop_labels` with `flow_from_directory`
        # which implicitly expects the top-level directories to be the crop names.
        # Since the data is structured as `Crop___Disease`, this will not work directly.
        # The `train_crop_detector.py` script's `get_crop_labels` and `flow_from_directory`
        # with `classes=crop_labels` is a workaround that might not be ideal.
        # A better approach for the crop detector would be to create a temporary directory structure
        # with only crop names, or use a custom `Sequence` or `Dataset`.
        # For now, this utility will focus on disease models where `classes` are the full labels.
        pass


    train_generator = train_datagen.flow_from_directory(
        os.path.join(data_dir, 'train'),
        target_size=target_size,
        batch_size=batch_size,
        class_mode=class_mode,
        classes=classes # Use provided classes for filtering
    )
    val_generator = val_datagen.flow_from_directory(
        os.path.join(data_dir, 'val'),
        target_size=target_size,
        batch_size=batch_size,
        class_mode=class_mode,
        classes=classes # Use provided classes for filtering
    )
    test_generator = test_datagen.flow_from_directory(
        os.path.join(data_dir, 'test'),
        target_size=target_size,
        batch_size=batch_size,
        class_mode=class_mode,
        classes=classes # Use provided classes for filtering
    )
    return train_generator, val_generator, test_generator

if __name__ == '__main__':
    # Example usage
    print("Crop Labels:", get_crop_labels())
    print("Corn Disease Labels:", get_disease_labels_for_crop('Corn'))
    print("Potato Disease Labels:", get_disease_labels_for_crop('Potato'))

    # Example for creating generators for a specific crop's diseases
    corn_disease_labels = get_disease_labels_for_crop('Corn')
    if corn_disease_labels:
        print(f"\nCreating generators for Corn diseases with labels: {corn_disease_labels}")
        train_gen, val_gen, test_gen = create_data_generators(
            classes=corn_disease_labels
        )
        print(f"Train samples for Corn diseases: {train_gen.samples}")
        print(f"Validation samples for Corn diseases: {val_gen.samples}")
        print(f"Test samples for Corn diseases: {test_gen.samples}")
    else:
        print("\nNo Corn disease labels found.")