# Mobile Application Implementation

The Krishi-Sahayak mobile application, developed using the Flutter framework, provides an intuitive and accessible interface for farmers to interact with the system. Its cross-platform nature ensures a consistent user experience across Android and iOS devices. This section details the application's architecture, key features, and the implementation of its core functionalities, including offline capabilities.

## A. Application Architecture and Technology Stack

The mobile application (`krishi_app/`) is built on Flutter, a UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. This choice facilitates rapid development and broad reach. The application's structure follows a typical Flutter project layout, with distinct directories for models, screens, services, and widgets, promoting modularity and maintainability.

*   **Framework**: Flutter (Dart language)
*   **Platform-Specific Files**:
    *   `krishi_app/android/`: Android-specific build configurations (e.g., `build.gradle.kts`, `google-services.json` for Firebase integration).
    *   `krishi_app/ios/`: iOS-specific configurations (e.g., `project.pbxproj`, `Runner-Bridging-Header.h`).
*   **Dependency Management**: `pubspec.yaml` and `pubspec.lock` manage project dependencies.

## B. Key Features and Functionalities

1.  **Crop Image Capture and Analysis**:
    *   **Camera Integration**: The `krishi_app/lib/screens/camera_screen.dart` is central to this feature, allowing users to capture images of their crops.
    *   **Image Preprocessing**: Captured images are prepared for machine learning inference, which may involve resizing, cropping, and normalization.

2.  **Real-time Crop Identification and Disease Detection**:
    *   **ML Service Integration**: The `krishi_app/lib/services/ml_service.dart` acts as an interface to the machine learning models. It handles sending images for inference (either locally or to the cloud service) and processing the results.
    *   **Model Assets**: TensorFlow Lite models (`.tflite`) are bundled within the application assets (`krishi_app/assets/models/`) for on-device inference. These include `corn_disease_model.tflite`, `crop_detector_model.tflite`, `multitask_crop_health_model.tflite`, `potato_disease_model.tflite`, etc., along with `labels.txt`.
    *   **Result Display**: `krishi_app/lib/widgets/crop_analysis_result.dart` is likely responsible for presenting the detection and identification results to the user in a clear and understandable format.

3.  **Crop Management and Information**:
    *   **Crop Data Model**: `krishi_app/lib/models/crop.dart` defines the data structure for storing crop-related information.
    *   **Crop Service**: `krishi_app/lib/services/crop_service.dart` manages the CRUD (Create, Read, Update, Delete) operations for crop data, potentially interacting with local storage or a backend API.
    *   **Crop Screen**: `krishi_app/lib/screens/crop_screen.dart` provides an interface for users to view and manage their registered crops.
    *   **Add Crop Dialog**: `krishi_app/lib/widgets/add_crop_dialog.dart` facilitates the addition of new crop entries.

4.  **User Experience and Utility Features**:
    *   **Configuration Management**: `krishi_app/lib/services/config_service.dart` handles application settings and configurations.
    *   **Connectivity Monitoring**: `krishi_app/lib/services/connectivity_service.dart` monitors network status, crucial for deciding between online and offline ML inference.
    *   **Error Handling**: `krishi_app/lib/services/error_handler_service.dart` provides a centralized mechanism for managing and displaying application errors.
    *   **Analytics**: `krishi_app/lib/services/firebase_analytics_service.dart` integrates Firebase Analytics for tracking user engagement and application performance, aiding in continuous improvement. `krishi_app/lib/widgets/analytics_dashboard.dart` might display these analytics within the app.
    *   **User Profile Management**: `krishi_app/lib/widgets/edit_profile_dialog.dart` allows users to manage their profile information.
    *   **Advanced Features Demo**: `krishi_app/lib/widgets/advanced_features_demo.dart` suggests the presence of a section showcasing more sophisticated functionalities.

## C. Offline Capabilities

A critical aspect of Krishi-Sahayak, particularly for farmers in remote areas, is its robust offline functionality.
*   **Offline ML Inference**: By embedding TensorFlow Lite models directly into the application assets (`krishi_app/assets/models/`), the mobile app can perform crop identification and disease detection without requiring an active internet connection. This is managed by `ml_service.dart`.
*   **Offline Maps**: The `krishi_app/lib/services/offline_maps_service.dart` indicates the capability to store and display maps locally, providing geographical context and location-based services even when offline. This is vital for field navigation and recording crop locations.
*   **Local Data Storage**: The application is designed to store essential user and crop data locally, ensuring continuity of operations and data integrity until an internet connection is restored for synchronization. The `OFFLINE_ML_IMPLEMENTATION.md` file further details these capabilities.

The mobile application's design prioritizes user-friendliness, performance, and resilience, making advanced agricultural tools accessible to a wide range of farmers, regardless of their connectivity status.