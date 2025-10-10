# Machine Learning Model Development

The core intelligence of the Krishi-Sahayak system lies in its sophisticated machine learning models, meticulously developed and optimized for accurate crop identification and disease detection. This section details the methodology employed for data preparation, model architecture, training procedures, and evaluation metrics.

## A. Data Preparation and Augmentation

High-quality and diverse datasets are crucial for training robust ML models. The data preparation phase involved:
*   **Data Collection**: Gathering a comprehensive dataset of crop images, including healthy plants and those exhibiting various disease symptoms. This likely involved a combination of publicly available datasets and potentially custom-collected images.
*   **Annotation**: Each image was meticulously annotated to label crop types and specific disease instances.
*   **Preprocessing**: Images were resized, normalized, and augmented to increase the dataset's variability and prevent overfitting. Augmentation techniques included rotation, flipping, zooming, and brightness adjustments. The presence of `SplitData_Crop/` suggests a structured approach to data organization for training.

## B. Model Architectures

Krishi-Sahayak employs a suite of specialized deep learning models, primarily based on Convolutional Neural Networks (CNNs), tailored for different detection tasks:

1.  **Crop Detector Model**: This model is responsible for identifying the type of crop present in an image. It acts as an initial classification layer, directing subsequent disease detection to the appropriate specialized model.
    *   **Training Script**: `krishi-model/scripts/train_crop_detector.py`
    *   **Saved Model**: `krishi-model/saved_models/crop_detector_model.h5` (Keras format) and `krishi-model/saved_models/crop_detector_model.tflite` (TensorFlow Lite for mobile).
    *   **Labels**: `krishi-model/model/crop_type_labels.txt`

2.  **Disease Detector Models (Crop-Specific)**: To achieve high accuracy, separate disease detection models were developed for key crops. This modular approach allows for fine-tuning and specialized feature extraction for each crop's unique disease patterns. Examples include:
    *   **Corn Disease Detector**:
        *   **Training Script**: `krishi-model/scripts/train_corn_disease_detector.py`
        *   **Saved Model**: `krishi-model/saved_models/corn_disease_detector_model.h5`, `krishi-model/saved_models/corn_disease_detector_model.tflite`
        *   **Labels**: `krishi-model/model/corn_disease_labels.txt`
    *   **Potato Disease Detector**:
        *   **Training Script**: `krishi-model/scripts/train_potato_disease_detector.py`
        *   **Saved Model**: `krishi-model/saved_models/potato_disease_detector_model.h5`, `krishi-model/saved_models/potato_disease_detector_model.tflite`
        *   **Labels**: `krishi-model/model/potato_disease_labels.txt`
    *   **Rice Disease Detector**:
        *   **Training Script**: `krishi-model/scripts/train_rice_disease_detector.py`
        *   **Saved Model**: `krishi-model/saved_models/rice_disease_detector_model.h5`, `krishi-model/saved_models/rice_disease_detector_model.tflite`
        *   **Labels**: `krishi-model/model/rice_disease_labels.txt`
    *   **Sugarcane Disease Detector**:
        *   **Training Script**: `krishi-model/scripts/train_sugarcane_disease_detector.py`
        *   **Saved Model**: `krishi-model/saved_models/sugarcane_disease_detector_model.h5`, `krishi-model/saved_models/sugarcane_disease_detector_model.tflite`
        *   **Labels**: `krishi-model/model/sugarcane_disease_labels.txt`
    *   **Wheat Disease Detector**:
        *   **Training Script**: `krishi-model/scripts/train_wheat_disease_detector.py`
        *   **Saved Model**: `krishi-model/saved_models/wheat_disease_detector_model.h5`, `krishi-model/saved_models/wheat_disease_detector_model.tflite`
        *   **Labels**: `krishi-model/model/wheat_disease_labels.txt`

3.  **Multitask Crop Health Model**: A more advanced model designed to perform both crop type identification and disease detection simultaneously. This model aims to improve efficiency and potentially leverage shared features between tasks.
    *   **Training Script**: `krishi-model/train_multitask_model.py`
    *   **Model Definition**: `krishi-model/model/multitask_model.py`
    *   **Saved Model**: `krishi-model/saved_models/multitask_model.h5`, `krishi-model/saved_models/multitask_model.tflite`
    *   **Mobile Asset**: `krishi_app/assets/models/multitask_crop_health_model.tflite`

The `krishi-model/model/best_model.h5` and `krishi-model/model/labels.txt` likely represent a generic or initial model and its corresponding labels, possibly used for early experimentation or as a baseline.

## C. Training and Optimization

Model training was conducted using TensorFlow/Keras, leveraging GPU acceleration for faster convergence.
*   **Training Scripts**: The `krishi-model/scripts/` directory contains individual training scripts for each specialized model, indicating a structured and reproducible training process. `krishi-model/train_multitask_model.py` is dedicated to the multitask model.
*   **Hyperparameter Tuning**: Various hyperparameters, including learning rate, batch size, and optimizer choice, were tuned to optimize model performance.
*   **Transfer Learning**: Pre-trained CNNs (e.g., MobileNetV2, as suggested by `krishi-model/notebooks/model/mobilenetv2_model.h5` and `krishi-model/notebooks/model/mobilenetv2_quant.tflite`) were likely used as base models, fine-tuned on the agricultural datasets to leverage learned features from large-scale image recognition tasks.
*   **Model Conversion**: For on-device inference in the mobile application, trained Keras models (`.h5`) were converted to TensorFlow Lite (`.tflite`) format using scripts like `krishi_app/convert_model.py` and `krishi_app/convert_multitask_model.py`. This conversion optimizes models for size and inference speed on mobile devices.

## D. Evaluation

Model performance was rigorously evaluated using standard metrics:
*   **Accuracy**: The proportion of correctly classified instances.
*   **Precision, Recall, F1-score**: Metrics to assess the model's ability to correctly identify positive cases and avoid false positives/negatives, particularly important for disease detection.
*   **Confusion Matrix**: Visual representation of classification performance, highlighting misclassifications.
*   **Log Analysis**: `krishi-model/logs/training_log.csv` indicates that training progress and metrics were logged for analysis and tracking.

The `krishi-model/notebooks/` directory, containing `disease.ipynb`, `sowing_logic.ipynb`, `testing.ipynb`, and `training.ipynb`, suggests an iterative development process involving extensive experimentation, data analysis, and model testing. `krishi-model/ml_utils.py` and `krishi-model/data_utils.py` provide reusable functions for ML operations and data handling, promoting code reusability and maintainability.