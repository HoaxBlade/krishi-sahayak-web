// ignore_for_file: avoid_print, await_only_futures

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';
import '../services/connectivity_service.dart';

class UsageEvent {
  final String eventType;
  final String? details;
  final DateTime timestamp;
  final bool isOnline;
  final Map<String, dynamic>? metadata;

  UsageEvent({
    required this.eventType,
    this.details,
    required this.timestamp,
    required this.isOnline,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventType': eventType,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'isOnline': isOnline,
      'metadata': metadata,
    };
  }

  factory UsageEvent.fromMap(Map<String, dynamic> map) {
    return UsageEvent(
      eventType: map['eventType'],
      details: map['details'],
      timestamp: DateTime.parse(map['timestamp']),
      isOnline: map['isOnline'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }
}

class SyncMetrics {
  final int totalSyncs;
  final int successfulSyncs;
  final int failedSyncs;
  final int conflictsResolved;
  final Duration averageSyncTime;
  final DateTime lastSyncTime;
  final int pendingOperations;

  SyncMetrics({
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.conflictsResolved,
    required this.averageSyncTime,
    required this.lastSyncTime,
    required this.pendingOperations,
  });

  double get successRate => totalSyncs > 0 ? successfulSyncs / totalSyncs : 0.0;
  double get failureRate => totalSyncs > 0 ? failedSyncs / totalSyncs : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'totalSyncs': totalSyncs,
      'successfulSyncs': successfulSyncs,
      'failedSyncs': failedSyncs,
      'conflictsResolved': conflictsResolved,
      'averageSyncTimeMs': averageSyncTime.inMilliseconds,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'pendingOperations': pendingOperations,
      'successRate': successRate,
      'failureRate': failureRate,
    };
  }
}

class OfflineAnalytics {
  final int totalOfflineSessions;
  final Duration totalOfflineTime;
  final int offlineOperations;
  final Map<String, int> offlineOperationTypes;
  final DateTime lastOfflineSession;

  OfflineAnalytics({
    required this.totalOfflineSessions,
    required this.totalOfflineTime,
    required this.offlineOperations,
    required this.offlineOperationTypes,
    required this.lastOfflineSession,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalOfflineSessions': totalOfflineSessions,
      'totalOfflineTimeMs': totalOfflineTime.inMilliseconds,
      'offlineOperations': offlineOperations,
      'offlineOperationTypes': offlineOperationTypes,
      'lastOfflineSession': lastOfflineSession.toIso8601String(),
      'averageOfflineTime': totalOfflineSessions > 0
          ? totalOfflineTime.inMinutes / totalOfflineSessions
          : 0.0,
    };
  }
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final PreferencesService _preferencesService = PreferencesService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final List<UsageEvent> _events = [];

  // Event tracking
  Future<void> trackEvent(
    String eventType, {
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    final event = UsageEvent(
      eventType: eventType,
      details: details,
      timestamp: DateTime.now(),
      isOnline: _connectivityService.isConnected,
      metadata: metadata,
    );

    _events.add(event);
    await _saveEvents();
  }

  // Sync metrics tracking
  Future<void> trackSyncStart() async {
    await trackEvent('sync_started');
  }

  Future<void> trackSyncSuccess({
    Duration? duration,
    int? conflictsResolved,
  }) async {
    await trackEvent(
      'sync_success',
      metadata: {
        'durationMs': duration?.inMilliseconds,
        'conflictsResolved': conflictsResolved,
      },
    );
  }

  Future<void> trackSyncFailure({String? error, Duration? duration}) async {
    await trackEvent(
      'sync_failed',
      details: error,
      metadata: {'durationMs': duration?.inMilliseconds},
    );
  }

  Future<void> trackConflictResolution(String strategy, String dataType) async {
    await trackEvent(
      'conflict_resolved',
      metadata: {'strategy': strategy, 'dataType': dataType},
    );
  }

  // Offline usage tracking
  Future<void> trackOfflineOperation(
    String operationType, {
    String? details,
  }) async {
    await trackEvent(
      'offline_operation',
      details: details,
      metadata: {'operationType': operationType},
    );
  }

  Future<void> trackOfflineSessionStart() async {
    await trackEvent('offline_session_start');
  }

  Future<void> trackOfflineSessionEnd({Duration? duration}) async {
    await trackEvent(
      'offline_session_end',
      metadata: {'durationMs': duration?.inMilliseconds},
    );
  }

  // Performance tracking
  Future<void> trackOperationPerformance(
    String operation,
    Duration duration,
  ) async {
    await trackEvent(
      'operation_performance',
      metadata: {'operation': operation, 'durationMs': duration.inMilliseconds},
    );
  }

  // Data persistence
  Future<void> _saveEvents() async {
    try {
      final eventsJson = jsonEncode(_events.map((e) => e.toMap()).toList());
      await _preferencesService.setSetting('analytics_events', eventsJson);
    } catch (e) {
      debugPrint('Error saving analytics events: $e');
    }
  }

  Future<void> _loadEvents() async {
    try {
      final eventsJson = await _preferencesService.getSetting(
        'analytics_events',
      );
      if (eventsJson != null) {
        final List<dynamic> eventsList = jsonDecode(eventsJson);
        _events.clear();
        _events.addAll(eventsList.map((e) => UsageEvent.fromMap(e)));
      }
    } catch (e) {
      debugPrint('Error loading analytics events: $e');
    }
  }

  // Analytics reports
  Future<SyncMetrics> getSyncMetrics() async {
    await _loadEvents();

    final syncEvents = _events
        .where((e) => e.eventType.startsWith('sync_'))
        .toList();

    final totalSyncs = syncEvents
        .where((e) => e.eventType == 'sync_started')
        .length;
    final successfulSyncs = syncEvents
        .where((e) => e.eventType == 'sync_success')
        .length;
    final failedSyncs = syncEvents
        .where((e) => e.eventType == 'sync_failed')
        .length;
    final conflictsResolved = syncEvents
        .where((e) => e.eventType == 'conflict_resolved')
        .length;

    // Calculate average sync time
    final syncDurations = syncEvents
        .where(
          (e) =>
              e.eventType == 'sync_success' &&
              e.metadata?['durationMs'] != null,
        )
        .map((e) => Duration(milliseconds: e.metadata!['durationMs']))
        .toList();

    final averageSyncTime = syncDurations.isNotEmpty
        ? Duration(
            milliseconds:
                syncDurations
                    .map((d) => d.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                syncDurations.length,
          )
        : Duration.zero;

    final lastSyncTime = syncEvents.isNotEmpty
        ? syncEvents.last.timestamp
        : DateTime.now();

    return SyncMetrics(
      totalSyncs: totalSyncs,
      successfulSyncs: successfulSyncs,
      failedSyncs: failedSyncs,
      conflictsResolved: conflictsResolved,
      averageSyncTime: averageSyncTime,
      lastSyncTime: lastSyncTime,
      pendingOperations: 0, // This would come from sync service
    );
  }

  Future<OfflineAnalytics> getOfflineAnalytics() async {
    await _loadEvents();

    final offlineEvents = _events
        .where((e) => e.eventType.startsWith('offline_'))
        .toList();

    final offlineSessions = offlineEvents
        .where((e) => e.eventType == 'offline_session_start')
        .length;

    final offlineOperations = offlineEvents
        .where((e) => e.eventType == 'offline_operation')
        .length;

    // Calculate offline operation types
    final operationTypes = <String, int>{};
    for (final event in offlineEvents.where(
      (e) => e.eventType == 'offline_operation',
    )) {
      final type = event.metadata?['operationType'] ?? 'unknown';
      operationTypes[type] = (operationTypes[type] ?? 0) + 1;
    }

    // Calculate total offline time (simplified)
    final totalOfflineTime = Duration(
      minutes: offlineSessions * 30,
    ); // Estimate

    final lastOfflineSession = offlineEvents.isNotEmpty
        ? offlineEvents.last.timestamp
        : DateTime.now();

    return OfflineAnalytics(
      totalOfflineSessions: offlineSessions,
      totalOfflineTime: totalOfflineTime,
      offlineOperations: offlineOperations,
      offlineOperationTypes: operationTypes,
      lastOfflineSession: lastOfflineSession,
    );
  }

  // Performance analytics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    await _loadEvents();

    final performanceEvents = _events
        .where((e) => e.eventType == 'operation_performance')
        .toList();

    final operationTimes = <String, List<int>>{};
    for (final event in performanceEvents) {
      final operation = event.metadata?['operation'] ?? 'unknown';
      final duration = event.metadata?['durationMs'] ?? 0;

      if (!operationTimes.containsKey(operation)) {
        operationTimes[operation] = [];
      }
      operationTimes[operation]!.add(duration);
    }

    final performanceMetrics = <String, dynamic>{};
    for (final entry in operationTimes.entries) {
      final times = entry.value;
      final avgTime = times.reduce((a, b) => a + b) / times.length;
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      final minTime = times.reduce((a, b) => a < b ? a : b);

      performanceMetrics[entry.key] = {
        'averageMs': avgTime,
        'maxMs': maxTime,
        'minMs': minTime,
        'count': times.length,
      };
    }

    return performanceMetrics;
  }

  // Clear analytics data
  Future<void> clearAnalytics() async {
    _events.clear();
    await _preferencesService.setSetting('analytics_events', '[]');
  }

  // Get comprehensive analytics report
  Future<Map<String, dynamic>> getComprehensiveReport() async {
    final syncMetrics = await getSyncMetrics();
    final offlineAnalytics = await getOfflineAnalytics();
    final performanceMetrics = await getPerformanceMetrics();

    return {
      'syncMetrics': syncMetrics.toMap(),
      'offlineAnalytics': offlineAnalytics.toMap(),
      'performanceMetrics': performanceMetrics,
      'totalEvents': _events.length,
      'reportGeneratedAt': DateTime.now().toIso8601String(),
    };
  }
}
