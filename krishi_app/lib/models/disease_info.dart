class DiseaseInfo {
  final String diseaseName;
  final String cropType;
  final String description;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> preventionMethods;
  final List<String> treatmentOptions;
  final String severity;
  final String seasonality;
  final String environmentalConditions;
  final DateTime lastUpdated;

  DiseaseInfo({
    required this.diseaseName,
    required this.cropType,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.preventionMethods,
    required this.treatmentOptions,
    required this.severity,
    required this.seasonality,
    required this.environmentalConditions,
    required this.lastUpdated,
  });

  factory DiseaseInfo.fromMap(Map<String, dynamic> map) {
    return DiseaseInfo(
      diseaseName: map['diseaseName'] ?? '',
      cropType: map['cropType'] ?? '',
      description: map['description'] ?? '',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      causes: List<String>.from(map['causes'] ?? []),
      preventionMethods: List<String>.from(map['preventionMethods'] ?? []),
      treatmentOptions: List<String>.from(map['treatmentOptions'] ?? []),
      severity: map['severity'] ?? 'Unknown',
      seasonality: map['seasonality'] ?? 'Unknown',
      environmentalConditions: map['environmentalConditions'] ?? 'Unknown',
      lastUpdated: DateTime.parse(
        map['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diseaseName': diseaseName,
      'cropType': cropType,
      'description': description,
      'symptoms': symptoms,
      'causes': causes,
      'preventionMethods': preventionMethods,
      'treatmentOptions': treatmentOptions,
      'severity': severity,
      'seasonality': seasonality,
      'environmentalConditions': environmentalConditions,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  DiseaseInfo copyWith({
    String? diseaseName,
    String? cropType,
    String? description,
    List<String>? symptoms,
    List<String>? causes,
    List<String>? preventionMethods,
    List<String>? treatmentOptions,
    String? severity,
    String? seasonality,
    String? environmentalConditions,
    DateTime? lastUpdated,
  }) {
    return DiseaseInfo(
      diseaseName: diseaseName ?? this.diseaseName,
      cropType: cropType ?? this.cropType,
      description: description ?? this.description,
      symptoms: symptoms ?? this.symptoms,
      causes: causes ?? this.causes,
      preventionMethods: preventionMethods ?? this.preventionMethods,
      treatmentOptions: treatmentOptions ?? this.treatmentOptions,
      severity: severity ?? this.severity,
      seasonality: seasonality ?? this.seasonality,
      environmentalConditions:
          environmentalConditions ?? this.environmentalConditions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper method to check if disease info is complete
  bool get isComplete {
    return diseaseName.isNotEmpty &&
        description.isNotEmpty &&
        symptoms.isNotEmpty &&
        preventionMethods.isNotEmpty;
  }

  // Helper method to get severity color
  String get severityColor {
    switch (severity.toLowerCase()) {
      case 'low':
        return 'green';
      case 'moderate':
        return 'orange';
      case 'high':
        return 'red';
      case 'critical':
        return 'purple';
      default:
        return 'grey';
    }
  }
}
