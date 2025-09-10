// ignore_for_file: unused_local_variable, await_only_futures, avoid_print

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';
import '../services/connectivity_service.dart';

class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String dataType;
  final int size;
  final int accessCount;
  final DateTime lastAccessed;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.dataType,
    required this.size,
    this.accessCount = 0,
    DateTime? lastAccessed,
  }) : lastAccessed = lastAccessed ?? createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isStale =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Duration get age => DateTime.now().difference(createdAt);
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'dataType': dataType,
      'size': size,
      'accessCount': accessCount,
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  factory CacheEntry.fromMap(Map<String, dynamic> map) {
    return CacheEntry(
      key: map['key'],
      data: map['data'],
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      dataType: map['dataType'],
      size: map['size'],
      accessCount: map['accessCount'] ?? 0,
      lastAccessed: DateTime.parse(map['lastAccessed']),
    );
  }

  CacheEntry copyWith({
    String? key,
    dynamic data,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? dataType,
    int? size,
    int? accessCount,
    DateTime? lastAccessed,
  }) {
    return CacheEntry(
      key: key ?? this.key,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      dataType: dataType ?? this.dataType,
      size: size ?? this.size,
      accessCount: accessCount ?? this.accessCount,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}

enum CachePolicy {
  aggressive, // Cache everything for long periods
  balanced, // Balanced caching with moderate expiration
  conservative, // Minimal caching, frequent refreshes
  networkOnly, // No caching, always fetch from network
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final PreferencesService _preferencesService = PreferencesService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final Map<String, CacheEntry> _memoryCache = {};

  CachePolicy _policy = CachePolicy.balanced;
  final int _maxMemorySize = 50 * 1024 * 1024; // 50MB
  int _currentMemorySize = 0;

  // Cache policies configuration
  static const Map<CachePolicy, Map<String, Duration>> _cacheDurations = {
    CachePolicy.aggressive: {
      'crops': Duration(hours: 24),
      'weather': Duration(hours: 6),
      'user_profile': Duration(days: 7),
      'analytics': Duration(days: 30),
    },
    CachePolicy.balanced: {
      'crops': Duration(hours: 12),
      'weather': Duration(hours: 2),
      'user_profile': Duration(days: 3),
      'analytics': Duration(days: 7),
    },
    CachePolicy.conservative: {
      'crops': Duration(hours: 2),
      'weather': Duration(minutes: 30),
      'user_profile': Duration(hours: 12),
      'analytics': Duration(days: 1),
    },
    CachePolicy.networkOnly: {
      'crops': Duration.zero,
      'weather': Duration.zero,
      'user_profile': Duration.zero,
      'analytics': Duration.zero,
    },
  };

  // Initialize cache service
  Future<void> initialize() async {
    await _loadCachePolicy();
    await _loadPersistentCache();
    _cleanupExpiredEntries();
  }

  // Set cache policy
  Future<void> setCachePolicy(CachePolicy policy) async {
    _policy = policy;
    await _preferencesService.setSetting('cache_policy', policy.toString());
    _cleanupExpiredEntries();
  }

  Future<void> _loadCachePolicy() async {
    final policyString = _preferencesService.getSetting('cache_policy');
    if (policyString != null) {
      _policy = CachePolicy.values.firstWhere(
        (p) => p.toString() == policyString,
        orElse: () => CachePolicy.balanced,
      );
    }
  }

  // Cache operations
  Future<void> set(String key, dynamic data, String dataType) async {
    if (_policy == CachePolicy.networkOnly) return;

    final duration = _getCacheDuration(dataType);
    if (duration == Duration.zero) return;

    final entry = CacheEntry(
      key: key,
      data: data,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(duration),
      dataType: dataType,
      size: _calculateSize(data),
    );

    // Add to memory cache
    _addToMemoryCache(entry);

    // Add to persistent cache
    await _addToPersistentCache(entry);
  }

  dynamic get(String key) {
    // Check memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      _updateAccessStats(memoryEntry);
      return memoryEntry.data;
    }

    // Check persistent cache
    final persistentEntry = _getFromPersistentCache(key);
    if (persistentEntry != null && !persistentEntry.isExpired) {
      _addToMemoryCache(persistentEntry);
      _updateAccessStats(persistentEntry);
      return persistentEntry.data;
    }

    return null;
  }

  Future<bool> has(String key) async {
    final entry = get(key);
    return entry != null;
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _removeFromPersistentCache(key);
  }

  Future<void> clear() async {
    _memoryCache.clear();
    _currentMemorySize = 0;
    await _clearPersistentCache();
  }

  // Smart cache management
  Future<void> _cleanupExpiredEntries() async {
    final now = DateTime.now();

    // Clean memory cache
    final expiredKeys = _memoryCache.keys.where((key) {
      final entry = _memoryCache[key]!;
      return entry.isExpired;
    }).toList();

    for (final key in expiredKeys) {
      final entry = _memoryCache[key]!;
      _currentMemorySize -= entry.size;
      _memoryCache.remove(key);
    }

    // Clean persistent cache
    await _cleanupPersistentCache();
  }

  Future<void> _evictLeastUsed() async {
    if (_currentMemorySize <= _maxMemorySize) return;

    // Sort by access count and last accessed time
    final entries = _memoryCache.values.toList();
    entries.sort((a, b) {
      if (a.accessCount != b.accessCount) {
        return a.accessCount.compareTo(b.accessCount);
      }
      return a.lastAccessed.compareTo(b.lastAccessed);
    });

    // Remove least used entries until under limit
    for (final entry in entries) {
      if (_currentMemorySize <= _maxMemorySize) break;

      _currentMemorySize -= entry.size;
      _memoryCache.remove(entry.key);
    }
  }

  void _addToMemoryCache(CacheEntry entry) {
    // Check if we need to evict entries
    if (_currentMemorySize + entry.size > _maxMemorySize) {
      _evictLeastUsed();
    }

    // Add entry
    _memoryCache[entry.key] = entry;
    _currentMemorySize += entry.size;
  }

  void _updateAccessStats(CacheEntry entry) {
    final updatedEntry = entry.copyWith(
      accessCount: entry.accessCount + 1,
      lastAccessed: DateTime.now(),
    );
    _memoryCache[entry.key] = updatedEntry;
  }

  Duration _getCacheDuration(String dataType) {
    return _cacheDurations[_policy]?[dataType] ?? Duration(hours: 1);
  }

  int _calculateSize(dynamic data) {
    if (data is String) return data.length;
    if (data is Map || data is List) return jsonEncode(data).length;
    return 1024; // Default size for other types
  }

  // Persistent cache operations
  Future<void> _loadPersistentCache() async {
    try {
      final cacheJson = await _preferencesService.getSetting(
        'persistent_cache',
      );
      if (cacheJson != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(cacheJson);
        for (final entry in cacheMap.entries) {
          final cacheEntry = CacheEntry.fromMap(entry.value);
          if (!cacheEntry.isExpired) {
            _memoryCache[entry.key] = cacheEntry;
            _currentMemorySize += cacheEntry.size;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading persistent cache: $e');
    }
  }

  Future<void> _addToPersistentCache(CacheEntry entry) async {
    try {
      final cacheJson = await _preferencesService.getSetting(
        'persistent_cache',
      );
      final Map<String, dynamic> cacheMap = cacheJson != null
          ? jsonDecode(cacheJson)
          : {};

      cacheMap[entry.key] = entry.toMap();
      await _preferencesService.setSetting(
        'persistent_cache',
        jsonEncode(cacheMap),
      );
    } catch (e) {
      debugPrint('Error adding to persistent cache: $e');
    }
  }

  CacheEntry? _getFromPersistentCache(String key) {
    // This would be implemented to read from persistent storage
    // For now, return null as we're using memory cache primarily
    return null;
  }

  Future<void> _removeFromPersistentCache(String key) async {
    try {
      final cacheJson = await _preferencesService.getSetting(
        'persistent_cache',
      );
      if (cacheJson != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(cacheJson);
        cacheMap.remove(key);
        await _preferencesService.setSetting(
          'persistent_cache',
          jsonEncode(cacheMap),
        );
      }
    } catch (e) {
      debugPrint('Error removing from persistent cache: $e');
    }
  }

  Future<void> _clearPersistentCache() async {
    await _preferencesService.setSetting('persistent_cache', '{}');
  }

  Future<void> _cleanupPersistentCache() async {
    try {
      final cacheJson = await _preferencesService.getSetting(
        'persistent_cache',
      );
      if (cacheJson != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(cacheJson);
        final now = DateTime.now();

        final expiredKeys = cacheMap.keys.where((key) {
          final entry = CacheEntry.fromMap(cacheMap[key]);
          return entry.isExpired;
        }).toList();

        for (final key in expiredKeys) {
          cacheMap.remove(key);
        }

        await _preferencesService.setSetting(
          'persistent_cache',
          jsonEncode(cacheMap),
        );
      }
    } catch (e) {
      debugPrint('Error cleaning persistent cache: $e');
    }
  }

  // Cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalEntries = _memoryCache.length;
    final expiredEntries = _memoryCache.values.where((e) => e.isExpired).length;
    final validEntries = totalEntries - expiredEntries;

    final dataTypeStats = <String, int>{};
    for (final entry in _memoryCache.values) {
      dataTypeStats[entry.dataType] = (dataTypeStats[entry.dataType] ?? 0) + 1;
    }

    return {
      'totalEntries': totalEntries,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'memoryUsageBytes': _currentMemorySize,
      'maxMemoryBytes': _maxMemorySize,
      'cachePolicy': _policy.toString(),
      'dataTypeStats': dataTypeStats,
      'hitRate': _calculateHitRate(),
    };
  }

  double _calculateHitRate() {
    // This would track cache hits vs misses
    // For now, return a placeholder value
    return 0.85;
  }

  // Smart prefetching
  Future<void> prefetchData(String dataType) async {
    if (!_connectivityService.isConnected) return;

    // Implement smart prefetching based on data type
    switch (dataType) {
      case 'weather':
        // Prefetch weather data for next few days
        break;
      case 'crops':
        // Prefetch crop data for current season
        break;
      case 'analytics':
        // Prefetch analytics data
        break;
    }
  }

  // Cache warming
  Future<void> warmCache() async {
    if (!_connectivityService.isConnected) return;

    // Warm up frequently accessed data
    await prefetchData('crops');
    await prefetchData('weather');
    await prefetchData('user_profile');
  }
}
