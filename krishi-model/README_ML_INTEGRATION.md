# ML Integration Setup Guide

This guide explains how to set up the ML integration between the Flutter app and Python ML model.

## Prerequisites

- Python 3.8+
- Flutter SDK
- Android Studio / Xcode (for mobile development)

## Setup Steps

### 1. Install Python Dependencies

```bash
cd krishi-model
pip install -r requirements.txt
```

### 2. Start the ML Server

```bash
python main.py
```

The server will:

- Load existing trained model (if available)
- Or train a new model using your existing training code
- Start Flask server on http://0.0.0.0:5000

### 3. Test the Server

```bash
python test_server.py
```

This will verify that all endpoints are working correctly.

### 4. Run Flutter App

```bash
cd krishi_app
flutter pub get
flutter run
```

## API Endpoints

- `GET /health` - Check server and model status
- `POST /analyze_crop` - Analyze crop image (send image as base64)
- `POST /train` - Retrain the model
- `GET /labels` - Get available crop labels

## Flutter Integration

The Flutter app now includes:

1. **ML Service** (`lib/services/ml_service.dart`) - Handles communication with Python server
2. **Camera Screen** (`lib/screens/camera_screen.dart`) - Captures and analyzes crop images
3. **Analysis Result Widget** (`lib/widgets/crop_analysis_result.dart`) - Displays ML results
4. **Updated Crop Screen** - Added ML analysis button

## Usage

1. Open the Flutter app
2. Go to "Crops" tab
3. Tap the camera icon in the app bar
4. Take a photo or select from gallery
5. Wait for ML analysis
6. View results (healthy/unhealthy, confidence, crop type)

## Troubleshooting

### Server Connection Issues

- Make sure Python server is running on port 5000
- Check firewall settings
- For physical devices, use your computer's IP address instead of localhost

### Model Loading Issues

- Ensure `model/mobilenetv2_model.h5` exists
- Check that `labels.txt` is present and readable
- Verify TensorFlow installation

### Flutter Issues

- Run `flutter clean` and `flutter pub get`
- Check that all dependencies are installed
- Verify camera permissions on device

## File Structure

```
krishi-model/
├── main.py                 # Flask server + ML integration
├── requirements.txt        # Python dependencies
├── test_server.py         # Server testing script
├── labels.txt             # Crop labels
├── model/                 # Trained models
└── utils/                 # Training utilities

krishi_app/
├── lib/
│   ├── services/
│   │   └── ml_service.dart        # ML communication service
│   ├── screens/
│   │   ├── crop_screen.dart       # Updated with ML button
│   │   └── camera_screen.dart     # Camera and analysis screen
│   └── widgets/
│       └── crop_analysis_result.dart  # ML results display
└── pubspec.yaml           # Flutter dependencies
```

## Next Steps

- Customize the health determination logic in `main.py`
- Add more detailed crop analysis features
- Implement model versioning and updates
- Add batch processing capabilities
- Integrate with weather data for better predictions
