// ignore_for_file: unnecessary_import

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'connectivity_service.dart';
import 'local_ml_service.dart';
import 'image_compression_service.dart';
import 'firebase_analytics_service.dart';

class MLService {
  static const String baseUrl =
      'http://35.222.33.77'; // Kubernetes ML server on Google Cloud
  // Use 'http://10.0.2.2:5001' for Android emulator
  // Use 'http://localhost:5001' for iOS simulator

  final http.Client _client = http.Client();
  final ConnectivityService _connectivityService = ConnectivityService();
  final LocalMLService _localML = LocalMLService();
  final ImageCompressionService _compressionService = ImageCompressionService();
  final FirebaseAnalyticsService _analytics = FirebaseAnalyticsService();
  bool _isLocalModelReady = false;

  Future<void> initialize() async {
    debugPrint('🚀 [MLService] Initializing ML service...');

    // Initialize local ML model
    try {
      debugPrint('📱 [MLService] Starting local ML model initialization...');
      await _localML.initialize();
      _isLocalModelReady = _localML.isReady;
      debugPrint('✅ [MLService] Local ML model ready: $_isLocalModelReady');
      debugPrint('📊 [MLService] Local ML service ready: ${_localML.isReady}');

      if (!_isLocalModelReady) {
        debugPrint(
          '⚠️ [MLService] Local ML model initialization completed but not ready',
        );
        debugPrint(
          '📊 [MLService] This usually means the TFLite model file is missing',
        );
        debugPrint(
          '📁 [MLService] Expected model path: assets/models/crop_health_model.tflite',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [MLService] Local ML model failed: $e');
      _isLocalModelReady = false;
    }

    debugPrint('✅ [MLService] ML service initialization completed');
  }

  Future<Map<String, dynamic>> analyzeCropHealth(XFile imageFile) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('🚀 [MLService] Starting crop health analysis...');

    try {
      // Check connectivity first
      debugPrint('📡 [MLService] Checking network connectivity...');
      final connectivityStart = Stopwatch()..start();
      bool isConnected = await _connectivityService.checkConnectivity();
      connectivityStart.stop();
      debugPrint(
        '📡 [MLService] Connectivity check completed in ${connectivityStart.elapsedMilliseconds}ms',
      );

      if (isConnected) {
        // Check server health before attempting analysis
        debugPrint('🏥 [MLService] Checking server health before analysis...');
        final serverHealthy = await checkServerHealth();

        if (serverHealthy) {
          // Use server model for best accuracy
          debugPrint('🌐 [MLService] Using server ML model (online mode)...');
          final result = await _analyzeWithServer(imageFile);
          result['model_type'] = 'server';
          result['processing_time'] = '${stopwatch.elapsedMilliseconds}ms';
          result['analysis_mode'] = 'online';
          stopwatch.stop();

          // Track analytics
          // Safely convert confidence to double
          double confidence = 0.0;
          if (result['confidence'] != null) {
            if (result['confidence'] is String) {
              confidence =
                  double.tryParse(result['confidence'] as String) ?? 0.0;
            } else if (result['confidence'] is num) {
              confidence = (result['confidence'] as num).toDouble();
            }
          }

          await _analytics.logCropAnalysis(
            analysisType: 'server',
            healthStatus: result['health_status'] ?? 'unknown',
            confidence: confidence,
            processingTimeMs: stopwatch.elapsedMilliseconds,
            modelType: 'server',
          );

          debugPrint(
            '🎉 [MLService] Server analysis completed in ${stopwatch.elapsedMilliseconds}ms total',
          );
          return result;
        } else {
          debugPrint(
            '⚠️ [MLService] Server is not healthy, falling back to local model...',
          );
          // Fall through to local model
        }
      }

      // Use local model for offline functionality or when server is unhealthy
      debugPrint(
        '📱 [MLService] Using local ML model (offline/fallback mode)...',
      );

      if (!_isLocalModelReady) {
        stopwatch.stop();
        debugPrint(
          '❌ [MLService] Local ML model not available offline after ${stopwatch.elapsedMilliseconds}ms',
        );
        throw Exception(
          'Local ML model not available offline. Please connect to internet for analysis.',
        );
      }

      final result = await _localML.analyzeImage(imageFile);
      result['model_type'] = 'local';
      result['processing_time'] = '${stopwatch.elapsedMilliseconds}ms';
      result['analysis_mode'] = 'offline';
      stopwatch.stop();

      // Track analytics
      // Safely convert confidence to double
      double confidence = 0.0;
      if (result['confidence'] != null) {
        if (result['confidence'] is String) {
          confidence = double.tryParse(result['confidence'] as String) ?? 0.0;
        } else if (result['confidence'] is num) {
          confidence = (result['confidence'] as num).toDouble();
        }
      }

      await _analytics.logCropAnalysis(
        analysisType: 'local',
        healthStatus: result['health_status'] ?? 'unknown',
        confidence: confidence,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        modelType: 'local',
      );

      debugPrint(
        '🎉 [MLService] Local analysis completed in ${stopwatch.elapsedMilliseconds}ms total',
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '💥 [MLService] Error occurred after ${stopwatch.elapsedMilliseconds}ms: $e',
      );

      // Try local model as fallback if server failed
      if (_isLocalModelReady) {
        debugPrint('🔄 [MLService] Attempting fallback to local model...');
        try {
          final fallbackResult = await _localML.analyzeImage(imageFile);
          fallbackResult['model_type'] = 'local_fallback';
          fallbackResult['processing_time'] =
              '${stopwatch.elapsedMilliseconds}ms';
          fallbackResult['analysis_mode'] = 'offline_fallback';
          fallbackResult['fallback_reason'] = 'Server analysis failed: $e';
          debugPrint('✅ [MLService] Fallback to local model successful');
          return fallbackResult;
        } catch (fallbackError) {
          debugPrint(
            '❌ [MLService] Fallback to local model also failed: $fallbackError',
          );
          throw Exception(
            'Both server and local analysis failed: $fallbackError',
          );
        }
      } else {
        debugPrint('⚠️ [MLService] Local ML model not ready for fallback');
        debugPrint('📊 [MLService] Local model status: $_isLocalModelReady');
        debugPrint(
          '📊 [MLService] Local ML service ready: ${_localML.isReady}',
        );
        throw Exception(
          'Server analysis failed and local model not available: $e',
        );
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeWithServer(XFile imageFile) async {
    debugPrint('🌐 [MLService] Starting server analysis...');

    // Track image compression
    debugPrint('🗜️ [MLService] Compressing image for ML analysis...');
    final compressionStart = Stopwatch()..start();
    Uint8List imageBytes = await _compressionService.optimizeForModel(
      imageFile,
      modelType: 'crop_health',
    );
    compressionStart.stop();
    debugPrint(
      '✅ [MLService] Image compression completed in ${compressionStart.elapsedMilliseconds}ms',
    );
    debugPrint(
      '📊 [MLService] Compressed size: ${imageBytes.length} bytes (${(imageBytes.length / 1024).toStringAsFixed(2)} KB)',
    );

    // Track base64 conversion
    debugPrint('🔄 [MLService] Converting image to base64...');
    final base64Start = Stopwatch()..start();
    String base64Image = base64Encode(imageBytes);
    String imageData = 'data:image/jpeg;base64,$base64Image';
    base64Start.stop();
    debugPrint(
      '✅ [MLService] Base64 conversion completed in ${base64Start.elapsedMilliseconds}ms',
    );
    debugPrint(
      '📊 [MLService] Base64 string length: ${imageData.length} characters',
    );

    // Track network request preparation
    debugPrint(
      '🌐 [MLService] Preparing network request to $baseUrl/analyze_crop...',
    );
    debugPrint(
      '📊 [MLService] Request payload size: ${jsonEncode({'image': imageData}).length} characters',
    );
    final requestStart = Stopwatch()..start();

    // Prepare request
    final response = await _client.post(
      Uri.parse('$baseUrl/analyze_crop'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': imageData}),
    );

    requestStart.stop();
    debugPrint(
      '✅ [MLService] Network request completed in ${requestStart.elapsedMilliseconds}ms',
    );
    debugPrint('📊 [MLService] Response status: ${response.statusCode}');
    debugPrint(
      '📊 [MLService] Response body length: ${response.body.length} characters',
    );
    debugPrint('📊 [MLService] Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      debugPrint('✅ [MLService] Server analysis successful');
      debugPrint('📊 [MLService] Final result keys: ${result.keys.toList()}');
      debugPrint(
        '📊 [MLService] Confidence type: ${result['confidence'].runtimeType}',
      );
      debugPrint(
        '📊 [MLService] Prediction class type: ${result['prediction_class'].runtimeType}',
      );
      debugPrint(
        '📊 [MLService] All predictions type: ${result['all_predictions'].runtimeType}',
      );

      // Extract new Gemini analysis fields
      final String? geminiAnalysisEnglish = result['gemini_analysis_english'];
      final String? geminiAnalysisHindi = result['gemini_analysis_hindi'];

      if (geminiAnalysisEnglish != null) {
        result['gemini_analysis_english'] = geminiAnalysisEnglish;
        debugPrint('📊 [MLService] Gemini English Analysis found.');
      }
      if (geminiAnalysisHindi != null) {
        result['gemini_analysis_hindi'] = geminiAnalysisHindi;
        debugPrint('📊 [MLService] Gemini Hindi Analysis found.');
      }

      return result;
    } else {
      debugPrint(
        '❌ [MLService] Server returned error status ${response.statusCode}',
      );
      debugPrint('📊 [MLService] Error response: ${response.body}');
      throw Exception('Failed to analyze image: ${response.statusCode}');
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      debugPrint('🏥 [MLService] Checking server health...');
      final response = await _client
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('✅ [MLService] Server is healthy and responding');
        return true;
      } else {
        debugPrint(
          '⚠️ [MLService] Server returned status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [MLService] Server health check failed: $e');
      return false;
    }
  }

  // Get current model status
  Map<String, dynamic> getModelStatus() {
    final localReady = _localML.isReady;
    final localStatus = _isLocalModelReady;

    debugPrint('📊 [MLService] Model Status Check:');
    debugPrint('  - Local ML Service Ready: $localReady');
    debugPrint('  - Local Model Status: $localStatus');
    debugPrint('  - Synchronized: ${localReady == localStatus}');

    // If there's a mismatch, try to sync
    if (localReady != localStatus) {
      debugPrint('🔄 [MLService] Syncing local model status...');
      _isLocalModelReady = localReady;
    }

    return {
      'local_ml_ready': localReady,
      'local_model_status': _isLocalModelReady,
      'server_available': true, // We'll check this when needed
    };
  }

  // Force local model analysis (for testing)
  Future<Map<String, dynamic>> analyzeWithLocalModel(XFile imageFile) async {
    if (!_isLocalModelReady) {
      throw Exception('Local ML model not initialized');
    }

    debugPrint('📱 [MLService] Forcing local model analysis...');
    final result = await _localML.analyzeImage(imageFile);
    result['model_type'] = 'local_forced';
    result['analysis_mode'] = 'offline_forced';
    return result;
  }

  // Test local ML model status
  Map<String, dynamic> testLocalMLStatus() {
    return {
      'ml_service_initialized': true,
      'local_model_ready': _isLocalModelReady,
      'local_ml_service_ready': _localML.isReady,
      'local_ml_service_initialized': _localML.isReady,
      'has_interpreter': _localML.isReady,
      'status_summary': _isLocalModelReady
          ? 'Local ML ready for fallback'
          : 'Local ML not ready - TFLite model missing',
    };
  }

  Future<void> refreshLocalModelStatus() async {
    debugPrint('🔄 [MLService] Refreshing local model status...');

    // Check current status
    final currentStatus = _localML.isReady;
    debugPrint('📊 [MLService] Current local ML status: $currentStatus');

    // Update our tracking
    _isLocalModelReady = currentStatus;
    debugPrint(
      '📊 [MLService] Updated local model status: $_isLocalModelReady',
    );

    // If not ready, try to re-initialize
    if (!_isLocalModelReady) {
      debugPrint('🔄 [MLService] Attempting to re-initialize local model...');
      try {
        await _localML.initialize();
        _isLocalModelReady = _localML.isReady;
        debugPrint(
          '✅ [MLService] Re-initialization result: $_isLocalModelReady',
        );
      } catch (e) {
        debugPrint('❌ [MLService] Re-initialization failed: $e');
        _isLocalModelReady = false;
      }
    }
  }

  void dispose() {
    debugPrint('🧹 [MLService] Disposing ML service...');
    _client.close();
    _localML.dispose();
  }
}
