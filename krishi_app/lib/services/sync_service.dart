// ignore_for_file: unused_field, avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/crop_service.dart';
import '../services/weather_service.dart';
import '../services/user_service.dart';
import '../services/error_handler_service.dart';
import '../models/versioned_data.dart';
import '../models/crop.dart';
import '../services/analytics_service.dart';

enum SyncStatus { idle, syncing, completed, failed }

class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isPending;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isPending = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isPending': isPending,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      type: json['type'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      isPending: json['isPending'] ?? true,
    );
  }
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final PreferencesService _preferencesService = PreferencesService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final CropService _cropService = CropService();
  final WeatherService _weatherService = WeatherService();
  final UserService _userService = UserService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  final ConflictResolutionService _conflictResolver =
      ConflictResolutionService();
  final AnalyticsService _analyticsService = AnalyticsService();

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final List<SyncOperation> _pendingOperations = [];

  Stream<SyncStatus> get syncStatus => _statusController.stream;
  SyncStatus _currentStatus = SyncStatus.idle;

  bool get isSyncing => _currentStatus == SyncStatus.syncing;
  List<SyncOperation> get pendingOperations =>
      List.unmodifiable(_pendingOperations);

  Future<void> initialize() async {
    await _loadPendingOperations();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivityService.connectionStatus.listen((isConnected) {
      if (isConnected && _pendingOperations.isNotEmpty) {
        _performSync();
      }
    });
  }

  Future<void> _loadPendingOperations() async {
    try {
      final operationsJson = _preferencesService.getSetting(
        'pending_sync_operations',
      );
      if (operationsJson != null) {
        final List<dynamic> operationsList = jsonDecode(operationsJson);
        _pendingOperations.clear();
        _pendingOperations.addAll(
          operationsList.map((op) => SyncOperation.fromJson(op)),
        );
      }
    } catch (e) {
      _errorHandler.handleException(e, operationId: 'load_pending_operations');
    }
  }

  Future<void> _savePendingOperations() async {
    try {
      final operationsJson = jsonEncode(
        _pendingOperations.map((op) => op.toJson()).toList(),
      );
      await _preferencesService.setSetting(
        'pending_sync_operations',
        operationsJson,
      );
    } catch (e) {
      _errorHandler.handleException(e, operationId: 'save_pending_operations');
    }
  }

  Future<void> addSyncOperation(String type, Map<String, dynamic> data) async {
    final operation = SyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    _pendingOperations.add(operation);
    await _savePendingOperations();

    // Try to sync immediately if online
    if (_connectivityService.isConnected) {
      _performSync();
    }
  }

  Future<void> _performSync() async {
    if (_currentStatus == SyncStatus.syncing || _pendingOperations.isEmpty) {
      return;
    }

    _setStatus(SyncStatus.syncing);
    final syncStartTime = DateTime.now();

    await _analyticsService.trackSyncStart();

    try {
      // Handle conflicts first
      await _handleConflicts();

      // Process pending operations
      for (final operation in List.from(_pendingOperations)) {
        await _processOperation(operation);
        _pendingOperations.remove(operation);
      }

      await _savePendingOperations();
      await _preferencesService.setLastSyncTime(DateTime.now());
      _setStatus(SyncStatus.completed);

      // Track successful sync
      final syncDuration = DateTime.now().difference(syncStartTime);
      await _analyticsService.trackSyncSuccess(duration: syncDuration);

      // Schedule next sync
      Timer(const Duration(minutes: 15), () {
        if (_connectivityService.isConnected) {
          _performSync();
        }
      });
    } catch (e) {
      final syncDuration = DateTime.now().difference(syncStartTime);
      await _analyticsService.trackSyncFailure(
        error: e.toString(),
        duration: syncDuration,
      );
      _errorHandler.handleException(e, operationId: 'sync_operation');
      _setStatus(SyncStatus.failed);
    }
  }

  Future<void> _handleConflicts() async {
    try {
      // Get local data for conflict detection
      final localCrops = await _cropService.getAllCrops();

      // Simulate server data (in real app, this would come from API)
      final serverCrops = await _getServerData();

      // Detect conflicts
      final conflicts = _conflictResolver.detectConflicts(
        localCrops,
        serverCrops,
      );

      if (conflicts.isNotEmpty) {
        debugPrint('Found ${conflicts.length} conflicts during sync');

        // Auto-resolve conflicts based on default strategy
        final resolvedData = _conflictResolver.autoResolveConflicts(conflicts);

        // Update local data with resolved versions
        for (final resolved in resolvedData) {
          if (resolved is Crop) {
            await _cropService.updateCrop(resolved);
          }
        }

        // Log conflict statistics
        final stats = _conflictResolver.getConflictStats(conflicts);
        debugPrint('Conflict resolution stats: $stats');
      }
    } catch (e) {
      _errorHandler.handleException(e, operationId: 'conflict_resolution');
    }
  }

  Future<List<VersionedData>> _getServerData() async {
    // Simulate server data - in real app, this would be an API call
    await Future.delayed(const Duration(milliseconds: 100));

    // Return empty list for now - in real implementation, this would fetch from server
    return [];
  }

  Future<void> _processOperation(SyncOperation operation) async {
    switch (operation.type) {
      case 'add_crop':
        await _syncAddCrop(operation.data);
        break;
      case 'update_crop':
        await _syncUpdateCrop(operation.data);
        break;
      case 'delete_crop':
        await _syncDeleteCrop(operation.data);
        break;
      case 'update_profile':
        await _syncUpdateProfile(operation.data);
        break;
      case 'cache_weather':
        await _syncCacheWeather(operation.data);
        break;
      default:
        debugPrint('Unknown sync operation type: ${operation.type}');
    }
  }

  Future<void> _syncAddCrop(Map<String, dynamic> data) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Synced add crop: ${data['name']}');
  }

  Future<void> _syncUpdateCrop(Map<String, dynamic> data) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Synced update crop: ${data['id']}');
  }

  Future<void> _syncDeleteCrop(Map<String, dynamic> data) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Synced delete crop: ${data['id']}');
  }

  Future<void> _syncUpdateProfile(Map<String, dynamic> data) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Synced update profile: ${data['name']}');
  }

  Future<void> _syncCacheWeather(Map<String, dynamic> data) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Synced weather data: ${data['date']}');
  }

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<void> forceSync() async {
    if (_connectivityService.isConnected) {
      await _performSync();
    } else {
      final error = _errorHandler.createNetworkError(
        'Cannot sync while offline',
        operationId: 'force_sync',
      );
      _errorHandler.handleError(error);
      throw Exception('Cannot sync while offline');
    }
  }

  Future<void> clearPendingOperations() async {
    _pendingOperations.clear();
    await _savePendingOperations();
  }

  Future<Map<String, dynamic>> getSyncStats() async {
    final lastSync = _preferencesService.getLastSyncTime();
    final isConnected = _connectivityService.isConnected;

    return {
      'lastSyncTime': lastSync?.toIso8601String(),
      'isConnected': isConnected,
      'pendingOperations': _pendingOperations.length,
      'syncStatus': _currentStatus.toString(),
    };
  }

  void dispose() {
    _statusController.close();
  }
}
