class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final int stockQuantity;
  final int minOrderQuantity;
  final String unit;
  final List<String> images;
  final Map<String, dynamic> specifications;
  final bool isActive;
  final bool isFeatured;
  final double ratingAvg;
  final int reviewCount;
  final String productType;
  final double? rentalPricePerDay;
  final double? rentalPricePerWeek;
  final double? rentalPricePerMonth;
  final int? minRentalDays;
  final int? maxRentalDays;
  final bool? requiresDeposit;
  final double? depositAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProviderProfile providerProfile;
  final Category category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.stockQuantity,
    required this.minOrderQuantity,
    required this.unit,
    required this.images,
    required this.specifications,
    required this.isActive,
    required this.isFeatured,
    required this.ratingAvg,
    required this.reviewCount,
    required this.productType,
    this.rentalPricePerDay,
    this.rentalPricePerWeek,
    this.rentalPricePerMonth,
    this.minRentalDays,
    this.maxRentalDays,
    this.requiresDeposit,
    this.depositAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.providerProfile,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      stockQuantity: json['stock_quantity'] as int,
      minOrderQuantity: json['min_order_quantity'] as int,
      unit: json['unit'] as String,
      images: List<String>.from(json['images'] ?? []),
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      isActive: json['is_active'] as bool,
      isFeatured: json['is_featured'] as bool,
      ratingAvg: (json['rating_avg'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      productType: json['product_type'] as String,
      rentalPricePerDay: json['rental_price_per_day'] != null
          ? (json['rental_price_per_day'] as num).toDouble()
          : null,
      rentalPricePerWeek: json['rental_price_per_week'] != null
          ? (json['rental_price_per_week'] as num).toDouble()
          : null,
      rentalPricePerMonth: json['rental_price_per_month'] != null
          ? (json['rental_price_per_month'] as num).toDouble()
          : null,
      minRentalDays: json['min_rental_days'] as int?,
      maxRentalDays: json['max_rental_days'] as int?,
      requiresDeposit: json['requires_deposit'] as bool?,
      depositAmount: json['deposit_amount'] != null
          ? (json['deposit_amount'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      providerProfile: ProviderProfile.fromJson(json['provider_profiles']),
      category: Category.fromJson(json['categories']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'stock_quantity': stockQuantity,
      'min_order_quantity': minOrderQuantity,
      'unit': unit,
      'images': images,
      'specifications': specifications,
      'is_active': isActive,
      'is_featured': isFeatured,
      'rating_avg': ratingAvg,
      'review_count': reviewCount,
      'product_type': productType,
      'rental_price_per_day': rentalPricePerDay,
      'rental_price_per_week': rentalPricePerWeek,
      'rental_price_per_month': rentalPricePerMonth,
      'min_rental_days': minRentalDays,
      'max_rental_days': maxRentalDays,
      'requires_deposit': requiresDeposit,
      'deposit_amount': depositAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'provider_profiles': providerProfile.toJson(),
      'categories': category.toJson(),
    };
  }

  // Helper methods
  String get displayPrice {
    if (discountPrice != null && discountPrice! < price) {
      return '₹${discountPrice!.toStringAsFixed(0)}';
    }
    return '₹${price.toStringAsFixed(0)}';
  }

  String get originalPrice {
    return '₹${price.toStringAsFixed(0)}';
  }

  bool get hasDiscount {
    return discountPrice != null && discountPrice! < price;
  }

  String get pricePerUnit {
    return '$displayPrice $unit';
  }

  String get stockStatus {
    if (stockQuantity == 0) {
      return 'Out of Stock';
    } else if (stockQuantity < 10) {
      return 'Only $stockQuantity left';
    } else {
      return '$stockQuantity available';
    }
  }

  String get location {
    return '${providerProfile.city}, ${providerProfile.state}';
  }

  bool get isRentable {
    return productType == 'rentable';
  }

  bool get isBuyable {
    return productType == 'buyable';
  }
}

class ProviderProfile {
  final String id;
  final String businessName;
  final String city;
  final String state;
  final double ratingAvg;
  final String verificationStatus;

  ProviderProfile({
    required this.id,
    required this.businessName,
    required this.city,
    required this.state,
    required this.ratingAvg,
    required this.verificationStatus,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      ratingAvg: (json['rating_avg'] as num).toDouble(),
      verificationStatus: json['verification_status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'city': city,
      'state': state,
      'rating_avg': ratingAvg,
      'verification_status': verificationStatus,
    };
  }

  bool get isVerified {
    return verificationStatus == 'verified';
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
