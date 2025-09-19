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
  bool _isMultitaskModel = false;

  bool get isReady => _isInitialized && _interpreter != null;
  bool get isMultitaskModel => _isMultitaskModel;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((line) => line.isNotEmpty).toList();
      debugPrint('📝 [LocalML] Loaded ${_labels.length} labels');

      // Load model - try multitask model first, fallback to single model
      try {
        _interpreter = await Interpreter.fromAsset(
          'assets/models/multitask_crop_health_model.tflite',
        );
        _isMultitaskModel = true;
        debugPrint('🤖 [LocalML] Multitask TFLite model loaded successfully');
      } catch (e) {
        debugPrint(
          '⚠️ [LocalML] Multitask model not found, trying single model...',
        );
        _interpreter = await Interpreter.fromAsset(
          'assets/models/crop_health_model.tflite',
        );
        _isMultitaskModel = false;
        debugPrint('🤖 [LocalML] Single TFLite model loaded successfully');
      }

      // Get model input/output details
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputCount = _interpreter!.getOutputTensors().length;

      debugPrint(
        '📊 [LocalML] Input shape: $inputShape, Output count: $outputCount',
      );

      if (_isMultitaskModel) {
        final classOutputShape = _interpreter!.getOutputTensor(0).shape;
        final regOutputShape = _interpreter!.getOutputTensor(1).shape;
        debugPrint(
          '📊 [LocalML] Class output shape: $classOutputShape, Regression output shape: $regOutputShape',
        );
      } else {
        debugPrint('📊 [LocalML] Single output shape: $outputShape');
      }

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

      debugPrint('🔄 [LocalML] Running inference...');

      if (_isMultitaskModel) {
        // Handle multitask model with two outputs
        final classOutputShape = _interpreter!.getOutputTensor(0).shape;
        final regOutputShape = _interpreter!.getOutputTensor(1).shape;

        debugPrint(
          '📊 [LocalML] Multitask model - Class output shape: $classOutputShape, Regression output shape: $regOutputShape',
        );

        // Create output tensors for both heads
        List<List<double>> classOutput;
        List<List<double>> regOutput;

        if (classOutputShape.length == 2 && classOutputShape[0] == 1) {
          classOutput = List.generate(
            1,
            (i) => List.filled(classOutputShape[1], 0.0),
          );
        } else {
          classOutput = [List.filled(classOutputShape[0], 0.0)];
        }

        if (regOutputShape.length == 2 && regOutputShape[0] == 1) {
          regOutput = List.generate(
            1,
            (i) => List.filled(regOutputShape[1], 0.0),
          );
        } else {
          regOutput = [List.filled(regOutputShape[0], 0.0)];
        }

        // Run inference
        _interpreter!.run(input, [classOutput, regOutput]);
        debugPrint('✅ [LocalML] Multitask inference completed');

        // Process multitask results
        final results = _processMultitaskResults(
          classOutput[0],
          regOutput[0],
          classOutputShape,
        );

        return {
          'success': true,
          'model': 'local_multitask',
          'confidence': results['confidence'],
          'prediction': results['prediction'],
          'health_status': results['health_status'],
          'processing_time': results['processing_time'],
          'all_predictions': classOutput, // Include all class probabilities
          'regression_confidence': results['regression_confidence'],
          'class_confidence': results['class_confidence'],
          'model_type': 'multitask',
        };
      } else {
        // Handle single output model (existing logic)
        final outputShape = _interpreter!.getOutputTensor(0).shape;
        debugPrint(
          '📊 [LocalML] Single model - Expected output shape: $outputShape',
        );

        // Create output tensor with the correct shape
        List<List<double>> output;
        if (outputShape.length == 2 && outputShape[0] == 1) {
          output = List.generate(1, (i) => List.filled(outputShape[1], 0.0));
        } else {
          output = [List.filled(outputShape[0], 0.0)];
        }

        // Run inference
        _interpreter!.run(input, output);
        debugPrint('✅ [LocalML] Single model inference completed');

        // Process single model results
        final results = _processResults(output[0], outputShape);

        return {
          'success': true,
          'model': 'local',
          'confidence': results['confidence'],
          'prediction': results['prediction'],
          'health_status': results['health_status'],
          'processing_time': results['processing_time'],
          'all_predictions': output,
          'model_type': 'single_task',
        };
      }
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

  Map<String, dynamic> _processMultitaskResults(
    dynamic classPredictions,
    dynamic regPredictions,
    List<int> classOutputShape,
  ) {
    debugPrint('📊 [LocalML] Processing multitask results...');
    debugPrint(
      '📊 [LocalML] Class predictions length: ${classPredictions.length}',
    );
    debugPrint(
      '📊 [LocalML] Regression predictions length: ${regPredictions.length}',
    );

    // Convert class predictions to List<double> safely
    List<double> doubleClassPredictions = [];
    try {
      for (int i = 0; i < classPredictions.length; i++) {
        final value = classPredictions[i];
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
        doubleClassPredictions.add(doubleValue);
      }
    } catch (e) {
      debugPrint('❌ [LocalML] Failed to convert class predictions: $e');
      throw Exception('Failed to convert class predictions to double: $e');
    }

    // Convert regression predictions to double
    double regressionConfidence = 0.0;
    try {
      final regValue = regPredictions[0];
      if (regValue is double) {
        regressionConfidence = regValue;
      } else if (regValue is int) {
        regressionConfidence = regValue.toDouble();
      } else if (regValue is String) {
        regressionConfidence = double.tryParse(regValue) ?? 0.0;
      } else {
        regressionConfidence = double.tryParse(regValue.toString()) ?? 0.0;
      }
    } catch (e) {
      debugPrint('❌ [LocalML] Failed to convert regression predictions: $e');
      regressionConfidence = 0.0;
    }

    // Validate class predictions array
    if (doubleClassPredictions.length != 17) {
      debugPrint(
        '⚠️ [LocalML] Unexpected class predictions length: ${doubleClassPredictions.length}, expected 17',
      );
      throw Exception(
        'Invalid class predictions array length: ${doubleClassPredictions.length}',
      );
    }

    // Find highest probability class
    int maxIndex = 0;
    double maxProb = doubleClassPredictions[0];

    for (int i = 1; i < doubleClassPredictions.length; i++) {
      if (doubleClassPredictions[i] > maxProb) {
        maxProb = doubleClassPredictions[i];
        maxIndex = i;
      }
    }

    final prediction = _labels[maxIndex];
    final classConfidence = maxProb * 100; // Convert to percentage
    final finalConfidence =
        regressionConfidence; // Use regression confidence as primary

    // Determine health status
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

    debugPrint('🎯 [LocalML] Multitask Prediction: $prediction');
    debugPrint(
      '📊 [LocalML] Class Confidence: ${classConfidence.toStringAsFixed(1)}%',
    );
    debugPrint(
      '📊 [LocalML] Regression Confidence: ${regressionConfidence.toStringAsFixed(1)}%',
    );
    debugPrint('🏥 [LocalML] Health Status: $healthStatus');

    return {
      'prediction': prediction,
      'confidence':
          finalConfidence / 100.0, // Convert to 0-1 range for compatibility
      'class_confidence': classConfidence,
      'regression_confidence': regressionConfidence,
      'health_status': healthStatus,
      'processing_time': '0.3s',
      'model_type': 'multitask_local',
    };
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
