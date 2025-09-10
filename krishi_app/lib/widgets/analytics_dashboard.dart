// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/cache_service.dart';
import '../services/sync_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final CacheService _cacheService = CacheService();
  final SyncService _syncService = SyncService();

  Map<String, dynamic>? _syncMetrics;
  Map<String, dynamic>? _offlineAnalytics;
  Map<String, dynamic>? _cacheStats;
  Map<String, dynamic>? _performanceMetrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final syncMetrics = await _analyticsService.getSyncMetrics();
      final offlineAnalytics = await _analyticsService.getOfflineAnalytics();
      final cacheStats = _cacheService.getCacheStats();
      final performanceMetrics = await _analyticsService
          .getPerformanceMetrics();

      if (mounted) {
        setState(() {
          _syncMetrics = syncMetrics.toMap();
          _offlineAnalytics = offlineAnalytics.toMap();
          _cacheStats = cacheStats;
          _performanceMetrics = performanceMetrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Unable to load analytics data. Please try again later.'),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSyncMetricsCard(),
                    const SizedBox(height: 16),
                    _buildOfflineAnalyticsCard(),
                    const SizedBox(height: 16),
                    _buildCacheStatsCard(),
                    const SizedBox(height: 16),
                    _buildPerformanceMetricsCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSyncMetricsCard() {
    if (_syncMetrics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Sync Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Total Syncs',
              _syncMetrics!['totalSyncs'].toString(),
            ),
            _buildMetricRow(
              'Successful',
              _syncMetrics!['successfulSyncs'].toString(),
            ),
            _buildMetricRow('Failed', _syncMetrics!['failedSyncs'].toString()),
            _buildMetricRow(
              'Success Rate',
              '${(_syncMetrics!['successRate'] * 100).toStringAsFixed(1)}%',
            ),
            _buildMetricRow(
              'Conflicts Resolved',
              _syncMetrics!['conflictsResolved'].toString(),
            ),
            _buildMetricRow(
              'Avg Sync Time',
              '${(_syncMetrics!['averageSyncTimeMs'] / 1000).toStringAsFixed(1)}s',
            ),
            _buildMetricRow(
              'Last Sync',
              _formatDateTime(_syncMetrics!['lastSyncTime']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineAnalyticsCard() {
    if (_offlineAnalytics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Offline Analytics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Offline Sessions',
              _offlineAnalytics!['totalOfflineSessions'].toString(),
            ),
            _buildMetricRow(
              'Total Offline Time',
              _formatDuration(_offlineAnalytics!['totalOfflineTimeMs']),
            ),
            _buildMetricRow(
              'Offline Operations',
              _offlineAnalytics!['offlineOperations'].toString(),
            ),
            _buildMetricRow(
              'Avg Session Time',
              '${_offlineAnalytics!['averageOfflineTime'].toStringAsFixed(1)} min',
            ),
            _buildMetricRow(
              'Last Offline Session',
              _formatDateTime(_offlineAnalytics!['lastOfflineSession']),
            ),
            if (_offlineAnalytics!['offlineOperationTypes'] is Map) ...[
              const SizedBox(height: 8),
              const Text(
                'Operation Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(_offlineAnalytics!['offlineOperationTypes'] as Map).entries
                  .map(
                    (entry) => _buildMetricRow(
                      '  ${entry.key}',
                      entry.value.toString(),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    if (_cacheStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Cache Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Total Entries',
              _cacheStats!['totalEntries'].toString(),
            ),
            _buildMetricRow(
              'Valid Entries',
              _cacheStats!['validEntries'].toString(),
            ),
            _buildMetricRow(
              'Expired Entries',
              _cacheStats!['expiredEntries'].toString(),
            ),
            _buildMetricRow(
              'Memory Usage',
              _formatBytes(_cacheStats!['memoryUsageBytes']),
            ),
            _buildMetricRow(
              'Max Memory',
              _formatBytes(_cacheStats!['maxMemoryBytes']),
            ),
            _buildMetricRow(
              'Hit Rate',
              '${(_cacheStats!['hitRate'] * 100).toStringAsFixed(1)}%',
            ),
            _buildMetricRow(
              'Cache Policy',
              _cacheStats!['cachePolicy'].toString().split('.').last,
            ),
            if (_cacheStats!['dataTypeStats'] is Map) ...[
              const SizedBox(height: 8),
              const Text(
                'Data Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(_cacheStats!['dataTypeStats'] as Map).entries.map(
                (entry) =>
                    _buildMetricRow('  ${entry.key}', entry.value.toString()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsCard() {
    if (_performanceMetrics == null || _performanceMetrics!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Performance Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_performanceMetrics as Map).entries.map((entry) {
              final metrics = entry.value as Map<String, dynamic>;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildMetricRow(
                    '  Average',
                    '${metrics['averageMs'].toStringAsFixed(1)}ms',
                  ),
                  _buildMetricRow('  Min', '${metrics['minMs']}ms'),
                  _buildMetricRow('  Max', '${metrics['maxMs']}ms'),
                  _buildMetricRow('  Count', metrics['count'].toString()),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _cacheService.clear();
                      _loadAnalytics();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _analyticsService.clearAnalytics();
                      _loadAnalytics();
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear Analytics'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _cacheService.warmCache();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cache warming initiated'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.whatshot),
                    label: const Text('Warm Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _syncService.forceSync();
                      _loadAnalytics();
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Force Sync'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
