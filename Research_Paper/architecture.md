# System Architecture

The Krishi-Sahayak system is designed with a modular, scalable, and resilient microservices architecture to ensure high availability, efficient resource utilization, and ease of maintenance. The overall system comprises several interconnected components: a mobile application, a web application, a machine learning (ML) inference service, and a robust cloud infrastructure managed by Kubernetes. Figure 1 illustrates the high-level system architecture.

## A. Component Overview

1.  **Mobile Application (krishi_app)**: Developed using Flutter, this cross-platform application serves as the primary interface for farmers. It provides functionalities for capturing crop images, real-time disease detection, crop type identification, and access to localized agricultural information. Key features include:
    *   **Image Capture and Preprocessing**: Utilizes the device camera to capture images, which are then preprocessed for optimal ML inference.
    *   **Offline ML Inference**: Integrates TensorFlow Lite models for on-device inference, enabling functionality even without internet connectivity.
    *   **Offline Maps and Data Storage**: Stores essential agricultural data and maps locally to support remote farming operations.
    *   **User Interface**: Intuitive design for ease of use, displaying analysis results and recommendations.
    *   **Services**: `config_service.dart`, `connectivity_service.dart`, `crop_service.dart`, `error_handler_service.dart`, `firebase_analytics_service.dart`, `ml_service.dart`, `offline_maps_service.dart` manage various aspects of the app's functionality.
    *   **Models**: `crop.dart` defines data structures for crop information.
    *   **Screens**: `camera_screen.dart`, `crop_screen.dart` provide the main user interactions.
    *   **Widgets**: `add_crop_dialog.dart`, `advanced_features_demo.dart`, `analytics_dashboard.dart`, `confirmation_dialog.dart`, `crop_analysis_result.dart`, `edit_profile_dialog.dart` offer reusable UI components.

2.  **Web Application (krishi_web, krishi_web_dev)**: Built with Next.js, this application provides a broader interface for administrators, agricultural experts, and potentially farmers for detailed analytics, data visualization, and advanced management features. It consumes data from the backend services and offers a comprehensive overview of agricultural trends and insights.
    *   **User Interface**: Responsive design for various devices, offering dashboards and reporting tools.
    *   **API Integration**: Communicates with the ML inference service and other backend components to fetch and display data.
    *   **Key Files**: `src/app/dashboard/page.tsx`, `src/app/learn-more/page.tsx` define core pages. `src/lib/marketplaceService.ts`, `src/lib/mlService.ts` handle service interactions.

3.  **Machine Learning Inference Service (krishi-model)**: This Python-based microservice hosts the trained ML models and provides an API for inference requests. It is designed to handle multiple model types and scales horizontally to accommodate varying loads.
    *   **Model Management**: Utilizes `multi_model_manager.py` to load and manage various TensorFlow/Keras models (e.g., `corn_disease_model.tflite`, `crop_detector_model.tflite`, `multitask_crop_health_model.tflite`, `potato_disease_model.tflite`, `rice_disease_model.tflite`, `sugarcane_disease_model.tflite`, `wheat_disease_model.tflite` from `krishi_app/assets/models/` and `krishi-model/saved_models/`).
    *   **API Endpoints**: Exposes RESTful APIs for receiving image inputs and returning prediction results.
    *   **Core Logic**: `main_production_multi.py` and `ml_utils.py` contain the main inference logic and utility functions.
    *   **Deployment**: Dockerized for consistent deployment across environments (`Dockerfile`, `Dockerfile.multi`, `Dockerfile.simple`).

## B. Cloud Infrastructure and Deployment

The entire system is deployed on a cloud platform, leveraging Kubernetes for container orchestration. This setup ensures scalability, reliability, and efficient management of microservices.

1.  **Kubernetes (k8s)**:
    *   **Deployment Manifests**: `k8s/deployment-model.yaml` and `k8s/deployment-web.yaml` define the deployments for the ML inference service and web application, respectively. These specify container images, resource limits, and scaling policies.
    *   **Service Manifests**: `k8s/service-model.yaml` and `k8s/service-web.yaml` expose the ML inference service and web application to internal and external traffic.
    *   **Containerization**: Both the ML service and web application are containerized using Docker, as evidenced by `krishi-model/Dockerfile` and `krishi_web/Dockerfile`.

2.  **MLOps CI/CD Pipeline**: The project incorporates a robust MLOps pipeline for continuous integration and deployment, as depicted in `Architecture-Diagrams/MLOps_CI_CD.mmd`. This pipeline automates the process of model training, versioning, testing, and deployment, ensuring that the deployed models are always up-to-date and performant.
    *   **Continuous Integration**: Automated testing and building of code changes.
    *   **Continuous Deployment**: Automated deployment of new application versions and ML models to the Kubernetes cluster.
    *   **Continuous Training**: Regular retraining of ML models with new data to maintain accuracy and adapt to evolving agricultural conditions.

## C. Data Flow

The data flow within the Krishi-Sahayak system is designed for efficiency and responsiveness, as illustrated in `Architecture-Diagrams/Data_Flow_Diagram.mmd`.
1.  **Image Capture**: A farmer captures an image of a crop using the mobile application.
2.  **Local Inference (Optional)**: If offline, the mobile application performs on-device ML inference using TensorFlow Lite models.
3.  **Cloud Inference**: If online, the mobile application sends the image to the ML Inference Service hosted on Kubernetes.
4.  **Prediction**: The ML Inference Service processes the image using the appropriate ML model and returns the prediction (crop type, disease detection) to the mobile application.
5.  **Data Storage and Analytics**: Prediction results and associated metadata are stored in a central database (not explicitly detailed in file structure but implied by a comprehensive system) for further analysis.
6.  **Web Dashboard**: The web application retrieves and visualizes this data, providing insights and analytics to users.

## D. Scalability and Resilience

The architecture is built with scalability and resilience in mind, as highlighted in `Architecture-Diagrams/Scalability_Resilience_Diagram.mmd`.
*   **Microservices**: Decoupling components allows independent scaling and development.
*   **Kubernetes**: Provides automated scaling, self-healing, and load balancing for all services.
*   **Cloud-Native**: Leverages cloud provider services for managed databases, storage, and networking, ensuring high availability and disaster recovery.

This comprehensive architecture ensures that Krishi-Sahayak can effectively serve a large user base, provide accurate and timely agricultural insights, and adapt to future technological advancements.