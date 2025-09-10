// ignore_for_file: avoid_print, unused_import

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'connectivity_service.dart';

enum ErrorType { network, database, sync, validation, unknown }

enum ErrorSeverity { low, medium, high, critical }

class AppError {
  final String message;
  final String? details;
  final ErrorType type;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final bool isRetryable;
  final int retryCount;
  final String? operationId;

  AppError({
    required this.message,
    this.details,
    required this.type,
    this.severity = ErrorSeverity.medium,
    DateTime? timestamp,
    this.isRetryable = true,
    this.retryCount = 0,
    this.operationId,
  }) : timestamp = timestamp ?? DateTime.now();

  AppError copyWith({
    String? message,
    String? details,
    ErrorType? type,
    ErrorSeverity? severity,
    DateTime? timestamp,
    bool? isRetryable,
    int? retryCount,
    String? operationId,
  }) {
    return AppError(
      message: message ?? this.message,
      details: details ?? this.details,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isRetryable: isRetryable ?? this.isRetryable,
      retryCount: retryCount ?? this.retryCount,
      operationId: operationId ?? this.operationId,
    );
  }
}

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();
  final List<AppError> _errorHistory = [];

  Stream<AppError> get errorStream => _errorController.stream;
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  // Error creation methods
  AppError createNetworkError(
    String message, {
    String? details,
    String? operationId,
  }) {
    return AppError(
      message: message,
      details: details,
      type: ErrorType.network,
      severity: _connectivityService.isConnected
          ? ErrorSeverity.medium
          : ErrorSeverity.high,
      isRetryable: true,
      operationId: operationId,
    );
  }

  AppError createDatabaseError(
    String message, {
    String? details,
    String? operationId,
  }) {
    return AppError(
      message: message,
      details: details,
      type: ErrorType.database,
      severity: ErrorSeverity.high,
      isRetryable: false,
      operationId: operationId,
    );
  }

  AppError createSyncError(
    String message, {
    String? details,
    String? operationId,
  }) {
    return AppError(
      message: message,
      details: details,
      type: ErrorType.sync,
      severity: ErrorSeverity.medium,
      isRetryable: true,
      operationId: operationId,
    );
  }

  AppError createValidationError(
    String message, {
    String? details,
    String? operationId,
  }) {
    return AppError(
      message: message,
      details: details,
      type: ErrorType.validation,
      severity: ErrorSeverity.low,
      isRetryable: false,
      operationId: operationId,
    );
  }

  // Error handling methods
  void handleError(AppError error) {
    _errorHistory.add(error);
    _errorController.add(error);

    // Log error for debugging
    debugPrint('Error: ${error.message}');
    if (error.details != null) {
      debugPrint('Details: ${error.details}');
    }
  }

  void handleException(dynamic exception, {String? operationId}) {
    AppError error;

    if (exception is AppError) {
      error = exception;
    } else if (exception.toString().contains('network') ||
        exception.toString().contains('connection')) {
      error = createNetworkError(
        'Network connection error',
        details: exception.toString(),
        operationId: operationId,
      );
    } else if (exception.toString().contains('database') ||
        exception.toString().contains('sql')) {
      error = createDatabaseError(
        'Database operation failed',
        details: exception.toString(),
        operationId: operationId,
      );
    } else {
      error = AppError(
        message: 'An unexpected error occurred',
        details: exception.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.medium,
        isRetryable: true,
        operationId: operationId,
      );
    }

    handleError(error);
  }

  // Retry mechanisms
  Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
    String? operationId,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          handleException(e, operationId: operationId);
          return null;
        }

        // Wait before retrying
        await Future.delayed(delay * attempts);
      }
    }

    return null;
  }

  // User-friendly error messages
  String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        if (!_connectivityService.isConnected) {
          return 'You are offline. Please check your internet connection and try again.';
        }
        return 'Network error. Please try again.';

      case ErrorType.database:
        return 'Data storage error. Please restart the app.';

      case ErrorType.sync:
        return 'Sync error. Your data will be saved locally and synced when online.';

      case ErrorType.validation:
        return 'Please check your input and try again.';

      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  // Error recovery suggestions
  List<String> getRecoverySuggestions(AppError error) {
    final suggestions = <String>[];

    switch (error.type) {
      case ErrorType.network:
        suggestions.add('Check your internet connection');
        suggestions.add('Try again in a few moments');
        if (!_connectivityService.isConnected) {
          suggestions.add('Your data will be saved locally');
        }
        break;

      case ErrorType.database:
        suggestions.add('Restart the app');
        suggestions.add('Check available storage space');
        break;

      case ErrorType.sync:
        suggestions.add('Your data is saved locally');
        suggestions.add('Sync will resume when online');
        suggestions.add('You can continue using the app offline');
        break;

      case ErrorType.validation:
        suggestions.add('Check all required fields');
        suggestions.add('Ensure data format is correct');
        break;

      case ErrorType.unknown:
        suggestions.add('Try again');
        suggestions.add('Restart the app if problem persists');
        break;
    }

    return suggestions;
  }

  // Error statistics
  Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    final recentErrors = _errorHistory
        .where((error) => error.timestamp.isAfter(last24Hours))
        .toList();

    final errorCounts = <ErrorType, int>{};
    for (final error in recentErrors) {
      errorCounts[error.type] = (errorCounts[error.type] ?? 0) + 1;
    }

    return {
      'totalErrors': _errorHistory.length,
      'recentErrors': recentErrors.length,
      'errorCounts': errorCounts,
      'lastError': _errorHistory.isNotEmpty
          ? _errorHistory.last.timestamp.toIso8601String()
          : null,
    };
  }

  // Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  void dispose() {
    _errorController.close();
  }
}
