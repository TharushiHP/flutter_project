class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String description;
  final String category;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final String? nutritionInfo;
  final String? origin;
  final DateTime? expiryDate;
  final int quantityInStock;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.category,
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.nutritionInfo,
    this.origin,
    this.expiryDate,
    this.quantityInStock = 0,
  });

  // Compatibility getter for legacy code
  bool get inStock => isAvailable;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      isAvailable: json['isAvailable'] ?? json['inStock'] ?? true,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      nutritionInfo: json['nutritionInfo'] ?? json['nutrition_info'],
      origin: json['origin'],
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.tryParse(json['expiryDate'])
              : null,
      quantityInStock:
          json['quantityInStock'] ?? json['quantity_in_stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'description': description,
      'category': category,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'nutritionInfo': nutritionInfo,
      'origin': origin,
      'expiryDate': expiryDate?.toIso8601String(),
      'quantityInStock': quantityInStock,
    };
  }

  // Database Map methods for local database operations
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      imageUrl: map['image_url'] ?? map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      isAvailable: (map['is_available'] ?? map['isAvailable'] ?? 1) == 1,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['review_count'] ?? map['reviewCount'] ?? 0,
      nutritionInfo: map['nutrition_info'] ?? map['nutritionInfo'],
      origin: map['origin'],
      expiryDate:
          map['expiry_date'] != null
              ? DateTime.tryParse(map['expiry_date'])
              : null,
      quantityInStock: map['quantity_in_stock'] ?? map['quantityInStock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'description': description,
      'category': category,
      'is_available': isAvailable ? 1 : 0,
      'rating': rating,
      'review_count': reviewCount,
      'nutrition_info': nutritionInfo,
      'origin': origin,
      'expiry_date': expiryDate?.toIso8601String(),
      'quantity_in_stock': quantityInStock,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    String? description,
    String? category,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    String? nutritionInfo,
    String? origin,
    DateTime? expiryDate,
    int? quantityInStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      origin: origin ?? this.origin,
      expiryDate: expiryDate ?? this.expiryDate,
      quantityInStock: quantityInStock ?? this.quantityInStock,
    );
  }
}
