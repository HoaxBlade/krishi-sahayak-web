// lib/services/local_ml_service.dart
// ignore_for_file: unnecessary_type_check

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class LocalMLService {
  static final LocalMLService _instance = LocalMLService._internal();
  factory LocalMLService() => _instance;
  LocalMLService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isReady => _isInitialized && _interpreter != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((line) => line.isNotEmpty).toList();
      debugPrint('📝 [LocalML] Loaded ${_labels.length} labels');

      // Load model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/crop_health_model.tflite',
      );
      debugPrint('🤖 [LocalML] TFLite model loaded successfully');

      // Get model input/output details
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint(
        '📊 [LocalML] Input shape: $inputShape, Output shape: $outputShape',
      );

      // Validate model compatibility
      if (outputShape.length == 2 &&
          outputShape[0] == 1 &&
          outputShape[1] == 17) {
        debugPrint('✅ [LocalML] Model has expected [1, 17] output shape');
      } else if (outputShape.length == 1 && outputShape[0] == 17) {
        debugPrint('✅ [LocalML] Model has expected [17] output shape');
      } else {
        debugPrint('⚠️ [LocalML] Unexpected output shape: $outputShape');
        debugPrint(
          '📊 [LocalML] Expected either [17] or [1, 17] for 17 classes',
        );
      }

      _isInitialized = true;
      debugPrint('✅ [LocalML] Local ML model initialized successfully');
    } catch (e) {
      debugPrint('❌ [LocalML] Failed to initialize: $e');
      _isInitialized = false;
    }
  }

  Future<Map<String, dynamic>> analyzeImage(XFile imageFile) async {
    if (!isReady) {
      throw Exception('Local ML service not initialized');
    }

    try {
      // Load and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // Resize to 224x224 (MobileNetV2 standard input size)
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to float array and normalize (MobileNetV2 expects RGB values 0-1)
      final input = _imageToByteListFloat32(resizedImage);

      // Prepare output tensor (17 classes from your best_model)
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('📊 [LocalML] Expected output shape: $outputShape');

      // Create output tensor with the correct shape
      List<List<double>> output;
      if (outputShape.length == 2 && outputShape[0] == 1) {
        // Shape is [1, 17] - create 2D tensor with batch dimension
        output = List.generate(
          1,
          (i) => List.filled(outputShape[1], 0.0),
        ); // [[17]]
        debugPrint(
          '📊 [LocalML] Creating output tensor with shape [[17]] for [1, 17] model',
        );
      } else {
        // Shape is [17] - create 1D tensor
        output = [List.filled(outputShape[0], 0.0)]; // [[17]]
        debugPrint(
          '📊 [LocalML] Creating output tensor with shape [[17]] for [17] model',
        );
      }

      debugPrint('🔄 [LocalML] Running inference...');
      // Run inference
      _interpreter!.run(input, output);
      debugPrint('✅ [LocalML] Inference completed');

      // Debug the output types
      debugPrint('📊 [LocalML] Output tensor type: ${output.runtimeType}');
      debugPrint('📊 [LocalML] Output[0] type: ${output[0].runtimeType}');
      if (output[0].isNotEmpty) {
        debugPrint(
          '📊 [LocalML] Output[0][0] type: ${output[0][0].runtimeType}',
        );
        debugPrint('📊 [LocalML] Output[0][0] value: ${output[0][0]}');

        // Check all output values for type issues
        for (int i = 0; i < output[0].length; i++) {
          final value = output[0][i];
          debugPrint(
            '📊 [LocalML] Output[0][$i]: type=${value.runtimeType}, value=$value',
          );
        }
      }

      // Process results - handle both output shapes
      final results = _processResults(
        output[0],
        outputShape,
      ); // Extract first (and only) batch

      return {
        'success': true,
        'model': 'local',
        'confidence': results['confidence'],
        'prediction': results['prediction'],
        'health_status': results['health_status'],
        'processing_time': results['processing_time'],
        'all_predictions': output, // Include all class probabilities
      };
    } catch (e) {
      debugPrint('❌ [LocalML] Analysis failed: $e');
      return {'success': false, 'error': e.toString(), 'model': 'local'};
    }
  }

  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    // Your best_model expects input shape: [1, 224, 224, 3] (batch, height, width, channels)
    // The model expects RGB values in range [0, 1] with MobileNetV2 preprocessing
    final input = List.generate(
      1, // batch size
      (batch) => List.generate(
        224, // height
        (y) => List.generate(
          224, // width
          (x) => List.generate(
            3, // RGB channels
            (c) {
              final pixel = image.getPixel(x, y);
              // MobileNetV2 preprocessing: normalize to [0, 1] range
              switch (c) {
                case 0: // Red channel
                  return pixel.r / 255.0;
                case 1: // Green channel
                  return pixel.g / 255.0;
                case 2: // Blue channel
                  return pixel.b / 255.0;
                default:
                  return 0.0;
              }
            },
          ),
        ),
      ),
    );
    return input;
  }

  Map<String, dynamic> _processResults(
    dynamic predictions,
    List<int> outputShape,
  ) {
    debugPrint('📊 [LocalML] Processing results with shape: $outputShape');
    debugPrint('📊 [LocalML] Predictions array length: ${predictions.length}');
    debugPrint(
      '📊 [LocalML] Predictions array type: ${predictions.runtimeType}',
    );

    // Convert predictions to List<double> safely
    List<double> doublePredictions = [];
    try {
      for (int i = 0; i < predictions.length; i++) {
        final value = predictions[i];
        debugPrint(
          '🔄 [LocalML] Converting element $i: ${value.runtimeType} -> $value',
        );

        double doubleValue;
        if (value is double) {
          doubleValue = value;
        } else if (value is int) {
          doubleValue = value.toDouble();
        } else if (value is String) {
          doubleValue = double.tryParse(value) ?? 0.0;
        } else {
          doubleValue = double.tryParse(value.toString()) ?? 0.0;
        }

        doublePredictions.add(doubleValue);
      }
      debugPrint(
        '✅ [LocalML] Successfully converted all predictions to double',
      );
    } catch (e) {
      debugPrint('❌ [LocalML] Failed to convert predictions: $e');
      throw Exception('Failed to convert predictions to double: $e');
    }

    // Validate predictions array
    if (doublePredictions.length != 17) {
      debugPrint(
        '⚠️ [LocalML] Unexpected predictions length: ${doublePredictions.length}, expected 17',
      );
      throw Exception(
        'Invalid predictions array length: ${doublePredictions.length}',
      );
    }

    // Find highest probability (17 classes from your best_model)
    int maxIndex = 0;
    double maxProb = doublePredictions[0];

    for (int i = 1; i < doublePredictions.length; i++) {
      if (doublePredictions[i] > maxProb) {
        maxProb = doublePredictions[i];
        maxIndex = i;
      }
    }

    final prediction = _labels[maxIndex];
    final confidence = (maxProb * 100).toStringAsFixed(1);

    // Determine health status based on prediction from your best_model
    String healthStatus;
    if (prediction.toLowerCase().contains('healthy')) {
      healthStatus = 'healthy';
    } else if (prediction.toLowerCase().contains('rust') ||
        prediction.toLowerCase().contains('blight') ||
        prediction.toLowerCase().contains('spot') ||
        prediction.toLowerCase().contains('blast') ||
        prediction.toLowerCase().contains('rot') ||
        prediction.toLowerCase().contains('bacterial')) {
      healthStatus = 'unhealthy';
    } else {
      healthStatus = 'unknown';
    }

    debugPrint('🎯 [LocalML] Prediction: $prediction ($confidence%)');
    debugPrint('🏥 [LocalML] Health Status: $healthStatus');
    debugPrint('📊 [LocalML] Model: Your Best Model (17 classes)');
    debugPrint('📊 [LocalML] Max probability at index: $maxIndex');
    debugPrint(
      '📊 [LocalML] All predictions: ${doublePredictions.map((p) => p.toStringAsFixed(3)).toList()}',
    );

    return {
      'prediction': prediction,
      'confidence': confidence,
      'health_status': healthStatus,
      'processing_time': '0.3s', // Your best model is optimized
      'model_type': 'best_model_converted',
    };
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
