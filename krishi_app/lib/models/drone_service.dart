class DroneService {
  final String id;
  final String name;
  final String description;
  final String serviceType;
  final double pricePerHour;
  final String coverageArea;
  final String availability;
  final List<String> features;
  final List<String> images;
  final String contactPhone;
  final String contactEmail;
  final String locationAddress;
  final String locationCity;
  final String locationState;
  final String locationPincode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? userProfile;

  DroneService({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceType,
    required this.pricePerHour,
    required this.coverageArea,
    required this.availability,
    required this.features,
    required this.images,
    required this.contactPhone,
    required this.contactEmail,
    required this.locationAddress,
    required this.locationCity,
    required this.locationState,
    required this.locationPincode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
  });

  factory DroneService.fromJson(Map<String, dynamic> json) {
    return DroneService(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      serviceType: json['service_type'] ?? '',
      pricePerHour: (json['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      coverageArea: json['coverage_area'] ?? '',
      availability: json['availability'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      contactPhone: json['contact_phone'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      locationAddress: json['location_address'] ?? '',
      locationCity: json['location_city'] ?? '',
      locationState: json['location_state'] ?? '',
      locationPincode: json['location_pincode'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      userProfile: json['user_profile'] != null
          ? UserProfile.fromJson(json['user_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'service_type': serviceType,
      'price_per_hour': pricePerHour,
      'coverage_area': coverageArea,
      'availability': availability,
      'features': features,
      'images': images,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'location_address': locationAddress,
      'location_city': locationCity,
      'location_state': locationState,
      'location_pincode': locationPincode,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_profile': userProfile?.toJson(),
    };
  }

  String get fullLocation => '$locationCity, $locationState - $locationPincode';

  String get formattedPrice => '₹${pricePerHour.toStringAsFixed(0)}/hour';

  List<String> get serviceTypes => [
    'Crop Monitoring',
    'Pest Detection',
    'Spraying Services',
    'Mapping & Surveying',
    'Weather Monitoring',
    'Livestock Monitoring',
    'Custom Services',
  ];
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? location;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.location,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
    };
  }
}
