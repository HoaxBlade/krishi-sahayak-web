import 'package:flutter/foundation.dart';
import '../models/product.dart' as models;
import 'supabase_service.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  /// Get all products with optional filters
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
      debugPrint('🛒 [MarketplaceService] Fetching products...');

      final productsData = await _supabaseService.getProducts(
        category: category,
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
      debugPrint(
        '✅ [MarketplaceService] Retrieved ${products.length} products',
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

      debugPrint(
        '✅ [MarketplaceService] Retrieved ${categories.length} categories',
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
}
