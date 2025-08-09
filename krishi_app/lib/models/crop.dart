// ignore_for_file: use_super_parameters

import 'versioned_data.dart';

class Crop extends VersionedData {
  final String name;
  final String? variety;
  final DateTime? plantingDate;
  final DateTime? harvestDate;
  final String? notes;
  final String status;

  Crop({
    required String id,
    required this.name,
    this.variety,
    this.plantingDate,
    this.harvestDate,
    this.notes,
    this.status = 'active',
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? lastModifiedBy,
    bool isDeleted = false,
  }) : super(
         id: id,
         version: version,
         createdAt: createdAt,
         updatedAt: updatedAt,
         lastModifiedBy: lastModifiedBy,
         isDeleted: isDeleted,
       );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'variety': variety,
      'planting_date': plantingDate?.toIso8601String(),
      'harvest_date': harvestDate?.toIso8601String(),
      'notes': notes,
      'status': status,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_modified_by': lastModifiedBy,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  @override
  String get dataType => 'crop';

  @override
  VersionedData createNewVersion({
    required DateTime updatedAt,
    String? lastModifiedBy,
  }) {
    return Crop(
      id: id,
      name: name,
      variety: variety,
      plantingDate: plantingDate,
      harvestDate: harvestDate,
      notes: notes,
      status: status,
      version: version + 1,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastModifiedBy: lastModifiedBy,
      isDeleted: isDeleted,
    );
  }

  @override
  VersionedData merge(VersionedData other) {
    if (other is! Crop) {
      throw Exception('Cannot merge Crop with ${other.dataType}');
    }

    return Crop(
      id: id,
      name: other.name, // Use newer name
      variety: other.variety ?? variety, // Prefer newer, fallback to local
      plantingDate: other.plantingDate ?? plantingDate,
      harvestDate: other.harvestDate ?? harvestDate,
      notes: other.notes ?? notes,
      status: other.status, // Use newer status
      version: version + 1,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastModifiedBy: other.lastModifiedBy,
      isDeleted: other.isDeleted,
    );
  }

  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id:
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] as String,
      variety: map['variety'] as String?,
      plantingDate: map['planting_date'] != null
          ? DateTime.parse(map['planting_date'] as String)
          : null,
      harvestDate: map['harvest_date'] != null
          ? DateTime.parse(map['harvest_date'] as String)
          : null,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'active',
      version: map['version'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastModifiedBy: map['last_modified_by'] as String?,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  Crop copyWith({
    String? id,
    String? name,
    String? variety,
    DateTime? plantingDate,
    DateTime? harvestDate,
    String? notes,
    String? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastModifiedBy,
    bool? isDeleted,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
