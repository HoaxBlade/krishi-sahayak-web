// ignore_for_file: avoid_print

import 'dart:convert';

abstract class VersionedData {
  final String id;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastModifiedBy;
  final bool isDeleted;

  VersionedData({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.lastModifiedBy,
    this.isDeleted = false,
  });

  // Abstract methods that must be implemented by subclasses
  Map<String, dynamic> toMap();
  String get dataType;

  // Version comparison methods
  bool isNewerThan(VersionedData other) {
    return version > other.version;
  }

  bool isOlderThan(VersionedData other) {
    return version < other.version;
  }

  bool hasConflicts(VersionedData other) {
    if (id != other.id || dataType != other.dataType) {
      return false; // Different entities, no conflict
    }

    // Check if both have been modified since last sync
    return version == other.version &&
        updatedAt.isAfter(other.updatedAt) &&
        other.updatedAt.isAfter(createdAt);
  }

  // Conflict detection based on content
  bool hasContentConflicts(VersionedData other) {
    if (id != other.id || dataType != other.dataType) {
      return false;
    }

    final thisData = toMap();
    final otherData = other.toMap();

    // Remove version-related fields for comparison
    thisData.remove('version');
    thisData.remove('createdAt');
    thisData.remove('updatedAt');
    thisData.remove('lastModifiedBy');
    thisData.remove('isDeleted');

    otherData.remove('version');
    otherData.remove('createdAt');
    otherData.remove('updatedAt');
    otherData.remove('lastModifiedBy');
    otherData.remove('isDeleted');

    return jsonEncode(thisData) != jsonEncode(otherData);
  }

  // Create a new version of this data
  VersionedData createNewVersion({
    required DateTime updatedAt,
    String? lastModifiedBy,
  });

  // Merge with another version
  VersionedData merge(VersionedData other);

  // Get conflict summary
  String getConflictSummary(VersionedData other) {
    if (!hasConflicts(other)) {
      return 'No conflicts detected';
    }

    final thisData = toMap();
    final otherData = other.toMap();

    final differences = <String>[];

    // Compare key fields
    for (final key in thisData.keys) {
      if (key != 'version' &&
          key != 'createdAt' &&
          key != 'updatedAt' &&
          key != 'lastModifiedBy' &&
          key != 'isDeleted') {
        if (thisData[key] != otherData[key]) {
          differences.add('$key: "${thisData[key]}" vs "${otherData[key]}"');
        }
      }
    }

    return differences.isEmpty
        ? 'Conflicts in version/timestamp only'
        : 'Conflicts in: ${differences.join(', ')}';
  }

  // Get human-readable conflict description
  String getConflictDescription(VersionedData other) {
    if (!hasConflicts(other)) {
      return 'No conflicts';
    }

    final thisTime = updatedAt;
    final otherTime = other.updatedAt;

    if (thisTime.isAfter(otherTime)) {
      return 'Local version is newer (${thisTime.difference(otherTime).inMinutes} minutes newer)';
    } else {
      return 'Server version is newer (${otherTime.difference(thisTime).inMinutes} minutes newer)';
    }
  }
}

// Conflict resolution strategies
enum ConflictResolutionStrategy { useLocal, useServer, merge, askUser, skip }

// Conflict information
class ConflictInfo {
  final VersionedData localData;
  final VersionedData serverData;
  final String conflictType;
  final String description;
  final List<String> differences;
  final ConflictResolutionStrategy defaultStrategy;

  ConflictInfo({
    required this.localData,
    required this.serverData,
    required this.conflictType,
    required this.description,
    required this.differences,
    required this.defaultStrategy,
  });

  Map<String, dynamic> toMap() {
    return {
      'localData': localData.toMap(),
      'serverData': serverData.toMap(),
      'conflictType': conflictType,
      'description': description,
      'differences': differences,
      'defaultStrategy': defaultStrategy.toString(),
    };
  }
}

// Conflict resolution service
class ConflictResolutionService {
  static final ConflictResolutionService _instance =
      ConflictResolutionService._internal();
  factory ConflictResolutionService() => _instance;
  ConflictResolutionService._internal();

  // Detect conflicts between local and server data
  List<ConflictInfo> detectConflicts(
    List<VersionedData> localData,
    List<VersionedData> serverData,
  ) {
    final conflicts = <ConflictInfo>[];

    for (final local in localData) {
      final server = serverData
          .where((s) => s.id == local.id && s.dataType == local.dataType)
          .firstOrNull;

      if (server != null && local.hasConflicts(server)) {
        conflicts.add(_createConflictInfo(local, server));
      }
    }

    return conflicts;
  }

  // Create conflict information
  ConflictInfo _createConflictInfo(VersionedData local, VersionedData server) {
    final differences = <String>[];
    final localMap = local.toMap();
    final serverMap = server.toMap();

    // Find differences in content
    for (final key in localMap.keys) {
      if (key != 'version' &&
          key != 'createdAt' &&
          key != 'updatedAt' &&
          key != 'lastModifiedBy' &&
          key != 'isDeleted') {
        if (localMap[key] != serverMap[key]) {
          differences.add('$key: "${localMap[key]}" vs "${serverMap[key]}"');
        }
      }
    }

    final conflictType = differences.isEmpty ? 'timestamp' : 'content';
    final description = local.getConflictDescription(server);

    // Determine default strategy
    ConflictResolutionStrategy defaultStrategy;
    if (local.isNewerThan(server)) {
      defaultStrategy = ConflictResolutionStrategy.useLocal;
    } else if (server.isNewerThan(local)) {
      defaultStrategy = ConflictResolutionStrategy.useServer;
    } else {
      defaultStrategy = ConflictResolutionStrategy.askUser;
    }

    return ConflictInfo(
      localData: local,
      serverData: server,
      conflictType: conflictType,
      description: description,
      differences: differences,
      defaultStrategy: defaultStrategy,
    );
  }

  // Resolve conflict based on strategy
  VersionedData resolveConflict(
    ConflictInfo conflict,
    ConflictResolutionStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        return conflict.localData;
      case ConflictResolutionStrategy.useServer:
        return conflict.serverData;
      case ConflictResolutionStrategy.merge:
        return conflict.localData.merge(conflict.serverData);
      case ConflictResolutionStrategy.skip:
        throw Exception('Conflict resolution skipped');
      case ConflictResolutionStrategy.askUser:
        throw Exception('User input required for conflict resolution');
    }
  }

  // Auto-resolve conflicts based on rules
  List<VersionedData> autoResolveConflicts(List<ConflictInfo> conflicts) {
    final resolved = <VersionedData>[];

    for (final conflict in conflicts) {
      try {
        final resolvedData = resolveConflict(
          conflict,
          conflict.defaultStrategy,
        );
        resolved.add(resolvedData);
      } catch (e) {
        // Skip conflicts that can't be auto-resolved
        print('Could not auto-resolve conflict: ${conflict.description}');
      }
    }

    return resolved;
  }

  // Get conflict statistics
  Map<String, dynamic> getConflictStats(List<ConflictInfo> conflicts) {
    final stats = <String, dynamic>{
      'totalConflicts': conflicts.length,
      'contentConflicts': conflicts
          .where((c) => c.conflictType == 'content')
          .length,
      'timestampConflicts': conflicts
          .where((c) => c.conflictType == 'timestamp')
          .length,
      'conflictsByDataType': <String, int>{},
    };

    for (final conflict in conflicts) {
      final dataType = conflict.localData.dataType;
      stats['conflictsByDataType'][dataType] =
          (stats['conflictsByDataType'][dataType] ?? 0) + 1;
    }

    return stats;
  }
}
