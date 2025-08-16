# ML Models Directory

This directory contains the TFLite models for offline crop health analysis.

## Required Files:

1. **crop_health_model.tflite** - Your converted TFLite model file
2. **labels.txt** - Model output labels (already created)

## How to Add Your Model:

1. Convert your server model to TFLite format
2. Optimize for mobile (quantization recommended)
3. Ensure file size is <20MB for app performance
4. Place the .tflite file in this directory
5. Update labels.txt if your model has different output classes

## Model Requirements:

- Input shape: 224x224x3 (RGB) or 224x224x1 (grayscale)
- Output: Probability scores for each class
- Format: TFLite (.tflite)
- Quantization: Recommended for mobile performance

## Testing:

After adding your model, test with:
```dart
// Force local model analysis
final result = await MLService().analyzeWithLocalModel(imageFile);
print('Local analysis result: $result');
```
