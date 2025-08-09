// ignore_for_file: avoid_print

import 'database_helper.dart';

class UserProfile {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? location;
  final double? farmSize;
  final int? experienceYears;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.location,
    this.farmSize,
    this.experienceYears,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'farm_size': farmSize,
      'experience_years': experienceYears,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      location: map['location'] as String?,
      farmSize: map['farm_size'] as double?,
      experienceYears: map['experience_years'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? location,
    double? farmSize,
    int? experienceYears,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      farmSize: farmSize ?? this.farmSize,
      experienceYears: experienceYears ?? this.experienceYears,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final profileData = await _dbHelper.getUserProfile();
      return profileData != null ? UserProfile.fromMap(profileData) : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create or update user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final existingProfile = await getUserProfile();

      if (existingProfile != null) {
        // Update existing profile
        final updatedProfile = profile.copyWith(id: existingProfile.id);
        final rowsAffected = await _dbHelper.updateUserProfile(
          updatedProfile.toMap(),
        );
        return rowsAffected > 0;
      } else {
        // Create new profile
        final id = await _dbHelper.insertUserProfile(profile.toMap());
        return id > 0;
      }
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Update specific profile fields
  Future<bool> updateProfileField(String field, dynamic value) async {
    try {
      final existingProfile = await getUserProfile();
      if (existingProfile == null) return false;

      Map<String, dynamic> updateData = {'id': existingProfile.id};
      updateData[field] = value;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final rowsAffected = await _dbHelper.updateUserProfile(updateData);
      return rowsAffected > 0;
    } catch (e) {
      print('Error updating profile field: $e');
      return false;
    }
  }

  // Check if user profile exists
  Future<bool> hasUserProfile() async {
    try {
      final profile = await getUserProfile();
      return profile != null;
    } catch (e) {
      print('Error checking user profile: $e');
      return false;
    }
  }

  // Get user's farming experience level
  String getExperienceLevel(int? experienceYears) {
    if (experienceYears == null) return 'Beginner';

    if (experienceYears < 2) return 'Beginner';
    if (experienceYears < 5) return 'Intermediate';
    if (experienceYears < 10) return 'Experienced';
    return 'Expert';
  }

  // Get farm size category
  String getFarmSizeCategory(double? farmSize) {
    if (farmSize == null) return 'Not specified';

    if (farmSize < 1) return 'Small (< 1 acre)';
    if (farmSize < 5) return 'Medium (1-5 acres)';
    if (farmSize < 20) return 'Large (5-20 acres)';
    return 'Commercial (> 20 acres)';
  }

  // Validate email format
  bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return true; // Optional field
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate phone format
  bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return true; // Optional field
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  // Get profile completion percentage
  Future<int> getProfileCompletionPercentage() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return 0;

      int completedFields = 1; // name is always present
      int totalFields =
          6; // name, phone, email, location, farm_size, experience_years

      if (profile.phone != null && profile.phone!.isNotEmpty) completedFields++;
      if (profile.email != null && profile.email!.isNotEmpty) completedFields++;
      if (profile.location != null && profile.location!.isNotEmpty) {
        completedFields++;
      }
      if (profile.farmSize != null) completedFields++;
      if (profile.experienceYears != null) completedFields++;

      return ((completedFields / totalFields) * 100).round();
    } catch (e) {
      print('Error calculating profile completion: $e');
      return 0;
    }
  }

  // Get profile summary for display
  Future<Map<String, String>> getProfileSummary() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) {
        return {
          'name': 'Not set',
          'location': 'Not set',
          'experience': 'Not set',
          'farmSize': 'Not set',
        };
      }

      return {
        'name': profile.name,
        'location': profile.location ?? 'Not set',
        'experience': profile.experienceYears != null
            ? '${profile.experienceYears} years (${getExperienceLevel(profile.experienceYears)})'
            : 'Not set',
        'farmSize': profile.farmSize != null
            ? '${profile.farmSize} acres (${getFarmSizeCategory(profile.farmSize)})'
            : 'Not set',
      };
    } catch (e) {
      print('Error getting profile summary: $e');
      return {
        'name': 'Error',
        'location': 'Error',
        'experience': 'Error',
        'farmSize': 'Error',
      };
    }
  }
}
