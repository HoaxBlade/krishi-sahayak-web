import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  /// Initialize Firebase Analytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      debugPrint('✅ [FirebaseAnalytics] Initialized successfully');
    } catch (e) {
      debugPrint('❌ [FirebaseAnalytics] Failed to initialize: $e');
    }
  }

  /// Get analytics instance
  FirebaseAnalytics? get analytics => _analytics;

  /// Track screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
        parameters: parameters,
      );
      debugPrint('📊 [FirebaseAnalytics] Screen view logged: $screenName');
    } catch (e) {
      debugPrint('❌ [FirebaseAnalytics] Error logging screen view: $e');
    }
  }

  /// Track custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
      debugPrint('📊 [FirebaseAnalytics] Event logged: $name');
    } catch (e) {
      debugPrint('❌ [FirebaseAnalytics] Error logging event: $e');
    }
  }

  /// Track crop analysis event
  Future<void> logCropAnalysis({
    required String analysisType,
    required String healthStatus,
    required double confidence,
    required int processingTimeMs,
    required String modelType,
  }) async {
    await logEvent(
      name: 'crop_analysis',
      parameters: {
        'analysis_type': analysisType,
        'health_status': healthStatus,
        'confidence': confidence,
        'processing_time_ms': processingTimeMs,
        'model_type': modelType,
      },
    );
  }

  /// Track weather check event
  Future<void> logWeatherCheck({
    required String location,
    required double temperature,
    required double humidity,
    required String description,
  }) async {
    await logEvent(
      name: 'weather_check',
      parameters: {
        'location': location,
        'temperature': temperature,
        'humidity': humidity,
        'description': description,
      },
    );
  }

  /// Track crop management event
  Future<void> logCropManagement({
    required String action,
    required String cropName,
    String? variety,
    String? status,
  }) async {
    await logEvent(
      name: 'crop_management',
      parameters: {
        'action': action,
        'crop_name': cropName,
        'variety': variety ?? '',
        'status': status ?? '',
      },
    );
  }

  /// Track app performance event
  Future<void> logAppPerformance({
    required String metric,
    required double value,
    String? unit,
  }) async {
    await logEvent(
      name: 'app_performance',
      parameters: {'metric': metric, 'value': value, 'unit': unit ?? ''},
    );
  }

  /// Track user engagement event
  Future<void> logUserEngagement({
    required String action,
    String? feature,
    Map<String, Object>? additionalParams,
  }) async {
    final parameters = <String, Object>{
      'action': action,
      'feature': feature ?? '',
    };

    if (additionalParams != null) {
      parameters.addAll(additionalParams);
    }

    await logEvent(name: 'user_engagement', parameters: parameters);
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
      debugPrint('📊 [FirebaseAnalytics] User property set: $name = $value');
    } catch (e) {
      debugPrint('❌ [FirebaseAnalytics] Error setting user property: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
      debugPrint('📊 [FirebaseAnalytics] User ID set: $userId');
    } catch (e) {
      debugPrint('❌ [FirebaseAnalytics] Error setting user ID: $e');
    }
  }

  /// Track app errors
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, Object>? additionalParams,
  }) async {
    final parameters = <String, Object>{
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace ?? '',
    };

    if (additionalParams != null) {
      parameters.addAll(additionalParams);
    }

    await logEvent(name: 'app_error', parameters: parameters);
  }

  /// Track feature usage
  Future<void> logFeatureUsage({
    required String featureName,
    required String action,
    Map<String, Object>? parameters,
  }) async {
    final eventParams = <String, Object>{
      'feature_name': featureName,
      'action': action,
    };

    if (parameters != null) {
      eventParams.addAll(parameters);
    }

    await logEvent(name: 'feature_usage', parameters: eventParams);
  }

  /// Check if analytics is ready
  bool get isReady => _isInitialized && _analytics != null;
}
