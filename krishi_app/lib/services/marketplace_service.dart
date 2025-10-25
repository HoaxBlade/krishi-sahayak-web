import 'package:flutter/foundation.dart';
import '../models/product.dart' as models;
import '../models/drone_service.dart';
import 'supabase_service.dart';
import 'drone_service_api.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final DroneServiceAPI _droneServiceAPI = DroneServiceAPI();

  /// Get all products with optional filters (including drone services)
  Future<List<models.Product>> getProducts({
    String? category,
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
      debugPrint(
        '🛒 [MarketplaceService] Fetching products and drone services...',
      );

      // Get regular products
      final productsData = await _supabaseService.getProducts(
        category: category == 'drone-services' ? null : category,
        search: search,
        minPrice: minPrice,
        maxPrice: maxPrice,
        location: location,
        sortBy: sortBy,
        ascending: ascending,
        page: page,
        limit: limit,
      );

      final products = productsData
          .map((data) => models.Product.fromJson(data))
          .toList();

      // If showing all products or specifically drone services, include drone services
      if (category == null ||
          category == 'all' ||
          category == 'drone-services') {
        final droneServicesData = await _supabaseService.getDroneServices(
          serviceType: category == 'drone-services' ? null : null,
          search: search,
          minPrice: minPrice,
          maxPrice: maxPrice,
          location: location,
          sortBy: sortBy,
          ascending: ascending,
          page: page,
          limit: limit,
        );

        // Transform drone services to product format
        final droneProducts = droneServicesData.map((serviceData) {
          return models.Product.fromJson({
            'id': serviceData['id'],
            'name': serviceData['name'],
            'description': serviceData['description'],
            'price': serviceData['price_per_hour'],
            'stock_quantity': 1, // Drone services are always available
            'min_order_quantity': 1,
            'unit': 'hour',
            'images': serviceData['images'] ?? [],
            'specifications': {
              'service_type': serviceData['service_type'],
              'coverage_area': serviceData['coverage_area'],
              'availability': serviceData['availability'],
              'features': serviceData['features'],
              'is_drone_service': true,
              'contact_phone': serviceData['contact_phone'],
              'contact_email': serviceData['contact_email'],
              'location_address': serviceData['location_address'],
              'location_city': serviceData['location_city'],
              'location_state': serviceData['location_state'],
              'location_pincode': serviceData['location_pincode'],
            },
            'is_active': serviceData['is_active'],
            'is_featured': false,
            'rating_avg': 0.0,
            'review_count': 0,
            'product_type': 'rentable',
            'rental_price_per_day':
                (serviceData['price_per_hour'] as num).toDouble() *
                8, // Approximate daily rate
            'created_at': serviceData['created_at'],
            'updated_at': serviceData['updated_at'],
            'provider_profiles': {
              'id':
                  serviceData['user_profile']?['id'] ?? serviceData['user_id'],
              'business_name':
                  serviceData['user_profile']?['name'] ??
                  'Drone Service Provider',
              'city': serviceData['location_city'] ?? 'Unknown',
              'state': serviceData['location_state'] ?? 'Unknown',
              'rating_avg': 0.0,
              'verification_status': 'verified',
            },
            'categories': {'id': 'drone-services', 'name': 'Drone Services'},
          });
        }).toList();

        products.addAll(droneProducts);
      }

      debugPrint(
        '✅ [MarketplaceService] Retrieved ${products.length} total items (products + drone services)',
      );
      return products;
    } catch (e) {
      debugPrint('❌ [MarketplaceService] Error fetching products: $e');
      rethrow;
    }
  }

  /// Get product categories
  Future<List<models.Category>> getCategories() async {
    try {
      debugPrint('📂 [MarketplaceService] Fetching categories...');

      final categoriesData = await _supabaseService.getCategories();
      final categories = categoriesData
          .map((data) => models.Category.fromJson(data))
          .toList();

      // Add Drone Services category
      categories.add(
        models.Category(id: 'drone-services', name: 'Drone Services'),
      );

      debugPrint(
        '✅ [MarketplaceService] Retrieved ${categories.length} categories (including drone services)',
      );
      return categories;
    } catch (e) {
      debugPrint('❌ [MarketplaceService] Error fetching categories: $e');
      rethrow;
    }
  }

  /// Create an order
  Future<Map<String, dynamic>> createOrder({
    required String productId,
    required int quantity,
    required Map<String, dynamic> shippingAddress,
    String? notes,
  }) async {
    try {
      debugPrint('🛒 [MarketplaceService] Creating order...');

      final order = await _supabaseService.createOrder(
        productId: productId,
        quantity: quantity,
        shippingAddress: shippingAddress,
        notes: notes,
      );

      debugPrint('✅ [MarketplaceService] Order created successfully');
      return order;
    } catch (e) {
      debugPrint('❌ [MarketplaceService] Error creating order: $e');
      rethrow;
    }
  }

  /// Search products
  Future<List<models.Product>> searchProducts(String query) async {
    return getProducts(search: query);
  }

  /// Get products by category
  Future<List<models.Product>> getProductsByCategory(String category) async {
    return getProducts(category: category);
  }

  /// Get featured products
  Future<List<models.Product>> getFeaturedProducts() async {
    return getProducts(sortBy: 'rating_avg', ascending: false);
  }

  /// Get products by price range
  Future<List<models.Product>> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    return getProducts(minPrice: minPrice, maxPrice: maxPrice);
  }

  /// Get products by location
  Future<List<models.Product>> getProductsByLocation(String location) async {
    return getProducts(location: location);
  }

  /// Drone Service Operations

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
      debugPrint('🚁 [MarketplaceService] Fetching drone services...');
      return await _droneServiceAPI.getDroneServices(
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
    } catch (e) {
      debugPrint('❌ [MarketplaceService] Error fetching drone services: $e');
      rethrow;
    }
  }

  /// Create a drone service
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
      debugPrint('🚁 [MarketplaceService] Creating drone service...');
      return await _droneServiceAPI.createDroneService(
        name: name,
        description: description,
        serviceType: serviceType,
        pricePerHour: pricePerHour,
        coverageArea: coverageArea,
        availability: availability,
        features: features,
        images: images,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        locationAddress: locationAddress,
        locationCity: locationCity,
        locationState: locationState,
        locationPincode: locationPincode,
      );
    } catch (e) {
      debugPrint('❌ [MarketplaceService] Error creating drone service: $e');
      rethrow;
    }
  }

  /// Search drone services
  Future<List<DroneService>> searchDroneServices(String query) async {
    return _droneServiceAPI.searchDroneServices(query);
  }

  /// Get drone services by service type
  Future<List<DroneService>> getDroneServicesByType(String serviceType) async {
    return _droneServiceAPI.getDroneServicesByType(serviceType);
  }

  /// Get drone services by price range
  Future<List<DroneService>> getDroneServicesByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    return _droneServiceAPI.getDroneServicesByPriceRange(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  /// Get drone services by location
  Future<List<DroneService>> getDroneServicesByLocation(String location) async {
    return _droneServiceAPI.getDroneServicesByLocation(location);
  }

  /// Get featured drone services
  Future<List<DroneService>> getFeaturedDroneServices() async {
    return _droneServiceAPI.getFeaturedDroneServices();
  }

  /// Get available service types
  List<String> getServiceTypes() {
    return _droneServiceAPI.getServiceTypes();
  }

  /// Get available features
  List<String> getAvailableFeatures() {
    return _droneServiceAPI.getAvailableFeatures();
  }
}
