class CropRecommendation {
  final String name;
  final String description;
  final String season;
  final String climate;
  final String soilType;
  final String waterRequirement;
  final String yieldPotential;
  final String marketValue;
  final List<String> benefits;
  final List<String> challenges;

  CropRecommendation({
    required this.name,
    required this.description,
    required this.season,
    required this.climate,
    required this.soilType,
    required this.waterRequirement,
    required this.yieldPotential,
    required this.marketValue,
    required this.benefits,
    required this.challenges,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      season: json['season'] ?? '',
      climate: json['climate'] ?? '',
      soilType: json['soilType'] ?? '',
      waterRequirement: json['waterRequirement'] ?? '',
      yieldPotential: json['yieldPotential'] ?? '',
      marketValue: json['marketValue'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      challenges: List<String>.from(json['challenges'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'season': season,
      'climate': climate,
      'soilType': soilType,
      'waterRequirement': waterRequirement,
      'yieldPotential': yieldPotential,
      'marketValue': marketValue,
      'benefits': benefits,
      'challenges': challenges,
    };
  }
}
