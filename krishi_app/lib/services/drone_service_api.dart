import 'package:flutter/foundation.dart';
import '../models/drone_service.dart';
import 'supabase_service.dart';

class DroneServiceAPI {
  static final DroneServiceAPI _instance = DroneServiceAPI._internal();
  factory DroneServiceAPI() => _instance;
  DroneServiceAPI._internal();

  final SupabaseService _supabaseService = SupabaseService();

  /// Get all drone services with optional filters
  Future<List<DroneService>> getDroneServices({
    String? serviceType,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sortBy,
    bool ascending = false,
    int? page,
    int? limit,
  }) async {
    try {
      debugPrint('🚁 [DroneServiceAPI] Fetching drone services...');

      final servicesData = await _supabaseService.getDroneServices(
        serviceType: serviceType,
        search: search,
        minPrice: minPrice,
        maxPrice: maxPrice,
        location: location,
        sortBy: sortBy,
        ascending: ascending,
        page: page,
        limit: limit,
      );

      final services = servicesData
          .map((data) => DroneService.fromJson(data))
          .toList();

      debugPrint(
        '✅ [DroneServiceAPI] Retrieved ${services.length} drone services',
      );
      return services;
    } catch (e) {
      debugPrint('❌ [DroneServiceAPI] Error fetching drone services: $e');
      rethrow;
    }
  }

  /// Create a new drone service
  Future<DroneService> createDroneService({
    required String name,
    required String description,
    required String serviceType,
    required double pricePerHour,
    required String coverageArea,
    required String availability,
    required List<String> features,
    required List<String> images,
    required String contactPhone,
    required String contactEmail,
    required String locationAddress,
    required String locationCity,
    required String locationState,
    required String locationPincode,
  }) async {
    try {
      debugPrint('🚁 [DroneServiceAPI] Creating drone service...');

      final serviceData = {
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
        'is_active': true,
      };

      final response = await _supabaseService.createDroneService(serviceData);
      final service = DroneService.fromJson(response);

      debugPrint('✅ [DroneServiceAPI] Drone service created successfully');
      return service;
    } catch (e) {
      debugPrint('❌ [DroneServiceAPI] Error creating drone service: $e');
      rethrow;
    }
  }

  /// Update an existing drone service
  Future<DroneService> updateDroneService({
    required String serviceId,
    String? name,
    String? description,
    String? serviceType,
    double? pricePerHour,
    String? coverageArea,
    String? availability,
    List<String>? features,
    List<String>? images,
    String? contactPhone,
    String? contactEmail,
    String? locationAddress,
    String? locationCity,
    String? locationState,
    String? locationPincode,
  }) async {
    try {
      debugPrint('🚁 [DroneServiceAPI] Updating drone service: $serviceId');

      final serviceData = <String, dynamic>{};

      if (name != null) {
        serviceData['name'] = name;
      }
      if (description != null) {
        serviceData['description'] = description;
      }
      if (serviceType != null) {
        serviceData['service_type'] = serviceType;
      }
      if (pricePerHour != null) {
        serviceData['price_per_hour'] = pricePerHour;
      }
      if (coverageArea != null) {
        serviceData['coverage_area'] = coverageArea;
      }
      if (availability != null) {
        serviceData['availability'] = availability;
      }
      if (features != null) {
        serviceData['features'] = features;
      }
      if (images != null) {
        serviceData['images'] = images;
      }
      if (contactPhone != null) {
        serviceData['contact_phone'] = contactPhone;
      }
      if (contactEmail != null) {
        serviceData['contact_email'] = contactEmail;
      }
      if (locationAddress != null) {
        serviceData['location_address'] = locationAddress;
      }
      if (locationCity != null) {
        serviceData['location_city'] = locationCity;
      }
      if (locationState != null) {
        serviceData['location_state'] = locationState;
      }
      if (locationPincode != null) {
        serviceData['location_pincode'] = locationPincode;
      }

      final response = await _supabaseService.updateDroneService(
        serviceId,
        serviceData,
      );
      final service = DroneService.fromJson(response);

      debugPrint('✅ [DroneServiceAPI] Drone service updated successfully');
      return service;
    } catch (e) {
      debugPrint('❌ [DroneServiceAPI] Error updating drone service: $e');
      rethrow;
    }
  }

  /// Delete a drone service (soft delete)
  Future<void> deleteDroneService(String serviceId) async {
    try {
      debugPrint('🚁 [DroneServiceAPI] Deleting drone service: $serviceId');

      await _supabaseService.deleteDroneService(serviceId);

      debugPrint('✅ [DroneServiceAPI] Drone service deleted successfully');
    } catch (e) {
      debugPrint('❌ [DroneServiceAPI] Error deleting drone service: $e');
      rethrow;
    }
  }

  /// Search drone services
  Future<List<DroneService>> searchDroneServices(String query) async {
    return getDroneServices(search: query);
  }

  /// Get drone services by service type
  Future<List<DroneService>> getDroneServicesByType(String serviceType) async {
    return getDroneServices(serviceType: serviceType);
  }

  /// Get drone services by price range
  Future<List<DroneService>> getDroneServicesByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    return getDroneServices(minPrice: minPrice, maxPrice: maxPrice);
  }

  /// Get drone services by location
  Future<List<DroneService>> getDroneServicesByLocation(String location) async {
    return getDroneServices(location: location);
  }

  /// Get featured drone services (sorted by creation date)
  Future<List<DroneService>> getFeaturedDroneServices() async {
    return getDroneServices(sortBy: 'created_at', ascending: false);
  }

  /// Get available service types
  List<String> getServiceTypes() {
    return [
      'Crop Monitoring',
      'Pest Detection',
      'Spraying Services',
      'Mapping & Surveying',
      'Weather Monitoring',
      'Livestock Monitoring',
      'Custom Services',
    ];
  }

  /// Get available features
  List<String> getAvailableFeatures() {
    return [
      'High Resolution Camera',
      'Thermal Imaging',
      'GPS Navigation',
      'Real-time Data Transmission',
      'Weather Resistant',
      'Long Flight Time',
      'Automated Flight Path',
      'Emergency Landing',
      'Insurance Coverage',
      'Certified Pilot',
    ];
  }
}
