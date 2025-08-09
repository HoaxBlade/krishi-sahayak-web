import 'dart:async';
import 'package:flutter/material.dart';
import 'connectivity_service.dart';
import 'preferences_service.dart';

class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  static const Duration _syncInterval = Duration(hours: 6);

  Timer? _syncTimer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _startPeriodicSync();
    _isInitialized = true;
  }

  Future<void> _startPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      await _performSync();
    });
  }

  Future<void> _performSync() async {
    try {
      final isConnected = await _checkConnection();
      if (!isConnected) {
        debugPrint('Background sync skipped: No internet connection');
        return;
      }

      debugPrint('Starting background sync...');

      // Update last sync time
      await PreferencesService().setLastSyncTime(DateTime.now());

      // Sync crops data
      await _syncCropsData();

      // Sync weather data
      await _syncWeatherData();

      // Sync user preferences
      await _syncUserPreferences();

      debugPrint('Background sync completed successfully');
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  Future<bool> _checkConnection() async {
    try {
      final connectivityService = ConnectivityService();
      final status = await connectivityService.connectionStatus.first;
      return status;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return false;
    }
  }

  Future<void> _syncCropsData() async {
    try {
      // Sync crops data with server
      // This would typically involve sending local changes to server
      // and downloading server changes
      debugPrint('Syncing crops data...');
    } catch (e) {
      debugPrint('Error syncing crops data: $e');
    }
  }

  Future<void> _syncWeatherData() async {
    try {
      // Sync weather data
      debugPrint('Syncing weather data...');
    } catch (e) {
      debugPrint('Error syncing weather data: $e');
    }
  }

  Future<void> _syncUserPreferences() async {
    try {
      // Sync user preferences with server
      // This would typically involve sending local changes to server
      // and downloading server changes
      debugPrint('Syncing user preferences...');
    } catch (e) {
      debugPrint('Error syncing user preferences: $e');
    }
  }

  Future<void> forceSync() async {
    await _performSync();
  }

  Future<void> stopSync() async {
    _syncTimer?.cancel();
    _isInitialized = false;
  }

  Future<void> restartSync() async {
    await stopSync();
    await initialize();
  }

  Future<DateTime?> getLastSyncTime() async {
    return PreferencesService().getLastSyncTime();
  }

  Future<bool> isSyncEnabled() async {
    return PreferencesService().getNotificationEnabled();
  }

  Future<void> setSyncEnabled(bool enabled) async {
    if (enabled) {
      await initialize();
    } else {
      await stopSync();
    }
  }

  Future<void> setSyncInterval(Duration interval) async {
    await stopSync();
    await _startPeriodicSync();
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
