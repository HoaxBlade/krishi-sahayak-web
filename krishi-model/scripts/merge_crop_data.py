import os
import shutil
from tqdm import tqdm

# Define paths
SOURCE_DATA_DIR = 'E:/PROJECTS/Krishi-Sahayak/krishi-model/SplitData'
TARGET_DATA_DIR = 'E:/PROJECTS/Krishi-Sahayak/krishi-model/SplitData_Crop'

def get_crop_types(source_dir):
    """Extracts unique crop types from the source data directory names."""
    crop_types = set()
    for split in ['train', 'val', 'test']:
        split_path = os.path.join(source_dir, split)
        if os.path.exists(split_path):
            for class_name in os.listdir(split_path):
                # Assuming class names are like 'Crop___Disease' or 'Crop_Healthy'
                crop_type = class_name.split('___')[0].split('_')[0]
                crop_types.add(crop_type)
    return sorted(list(crop_types))

def merge_and_label_crop_data(source_dir, target_dir):
    """
    Merges all disease-specific data for each crop into a single crop-specific directory
    in the target location.
    """
    crop_types = get_crop_types(source_dir)
    print(f"Found crop types: {crop_types}")

    for split in ['train', 'val', 'test']:
        source_split_path = os.path.join(source_dir, split)
        target_split_path = os.path.join(target_dir, split)

        if not os.path.exists(source_split_path):
            print(f"Source split path does not exist: {source_split_path}. Skipping.")
            continue

        os.makedirs(target_split_path, exist_ok=True)
        print(f"Processing split: {split}")

        for crop_type in tqdm(crop_types, desc=f"Merging {split} data"):
            target_crop_path = os.path.join(target_split_path, crop_type)
            os.makedirs(target_crop_path, exist_ok=True)

            # Iterate through all class directories in the source split
            for class_name in os.listdir(source_split_path):
                if class_name.startswith(f"{crop_type}___") or class_name.startswith(f"{crop_type}_"):
                    source_class_path = os.path.join(source_split_path, class_name)
                    if os.path.isdir(source_class_path):
                        for filename in os.listdir(source_class_path):
                            source_file_path = os.path.join(source_class_path, filename)
                            target_file_path = os.path.join(target_crop_path, filename)
                            # Copy the file, overwrite if it exists (shouldn't happen with unique filenames)
                            shutil.copy2(source_file_path, target_file_path)

    print(f"Data merging complete. Merged data is available in: {target_dir}")

if __name__ == '__main__':
    merge_and_label_crop_data(SOURCE_DATA_DIR, TARGET_DATA_DIR)