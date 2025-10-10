class CropAnalysis {
  final String id;
  final String? userId;
  final String imageUrl;
  final String cropType;
  final String diseaseType;
  final String healthStatus;
  final bool isHealthy;
  final double confidence;
  final int predictionClass;
  final Map<String, dynamic> allPredictions;
  final String modelType;
  final String analysisMode;
  final String processingTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropAnalysis({
    required this.id,
    this.userId,
    required this.imageUrl,
    required this.cropType,
    required this.diseaseType,
    required this.healthStatus,
    required this.isHealthy,
    required this.confidence,
    required this.predictionClass,
    required this.allPredictions,
    required this.modelType,
    required this.analysisMode,
    required this.processingTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CropAnalysis.fromMap(Map<String, dynamic> map) {
    return CropAnalysis(
      id: map['id'] ?? '',
      userId: map['user_id'],
      imageUrl: map['image_url'] ?? '',
      cropType: map['crop_type'] ?? '',
      diseaseType: map['disease_type'] ?? '',
      healthStatus: map['health_status'] ?? '',
      isHealthy: map['is_healthy'] ?? false,
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      predictionClass: map['prediction_class'] ?? 0,
      allPredictions: Map<String, dynamic>.from(map['all_predictions'] ?? {}),
      modelType: map['model_type'] ?? '',
      analysisMode: map['analysis_mode'] ?? '',
      processingTime: map['processing_time'] ?? '',
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'crop_type': cropType,
      'disease_type': diseaseType,
      'health_status': healthStatus,
      'is_healthy': isHealthy,
      'confidence': confidence,
      'prediction_class': predictionClass,
      'all_predictions': allPredictions,
      'model_type': modelType,
      'analysis_mode': analysisMode,
      'processing_time': processingTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CropAnalysis copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? cropType,
    String? diseaseType,
    String? healthStatus,
    bool? isHealthy,
    double? confidence,
    int? predictionClass,
    Map<String, dynamic>? allPredictions,
    String? modelType,
    String? analysisMode,
    String? processingTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropAnalysis(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      cropType: cropType ?? this.cropType,
      diseaseType: diseaseType ?? this.diseaseType,
      healthStatus: healthStatus ?? this.healthStatus,
      isHealthy: isHealthy ?? this.isHealthy,
      confidence: confidence ?? this.confidence,
      predictionClass: predictionClass ?? this.predictionClass,
      allPredictions: allPredictions ?? this.allPredictions,
      modelType: modelType ?? this.modelType,
      analysisMode: analysisMode ?? this.analysisMode,
      processingTime: processingTime ?? this.processingTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
