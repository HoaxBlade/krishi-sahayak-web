import os

# Rate limiting configuration
RATE_LIMIT_REQUESTS = int(os.getenv('RATE_LIMIT_REQUESTS', '100'))  # requests per window
RATE_LIMIT_WINDOW = int(os.getenv('RATE_LIMIT_WINDOW', '3600'))  # 1 hour in seconds
MAX_FILE_SIZE = int(os.getenv('MAX_FILE_SIZE', '10485760'))  # 10MB

# Model and Label Paths
MODEL_PATHS = [
    "saved_models/best_modelV1.h5",
    "notebooks/model/best_model.h5",
    "notebooks/model/mobilenetv2_model.h5",
    "model/best_model.h5",
    "model/mobilenetv2_model.h5"
]

LABEL_PATHS = ["labels.txt", "notebooks/model/labels.txt", "model/labels.txt"]

# System Health Thresholds
MEMORY_HEALTH_THRESHOLD = 90
CPU_HEALTH_THRESHOLD = int(os.getenv('CPU_HEALTH_THRESHOLD', '95')) # Unified threshold, can be overridden by environment variable.

# Image Preprocessing
IMAGE_SIZE = (224, 224) # Standard for MobileNetV2

# Server Configuration
FLASK_PORT = int(os.getenv('PORT', 5000)) # Default to 5000 for production, 5001 for development
FLASK_HOST = '0.0.0.0'