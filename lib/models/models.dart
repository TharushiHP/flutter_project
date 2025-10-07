// Database Models for Grocery Store App
// Export all models for easy importing
export 'product.dart';
export 'category.dart';
export 'cart.dart';
export 'cart_item.dart';
export 'device_info.dart';
export 'api_models.dart'; // Laravel API models

class CartItem {
  final int? id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;
  final DateTime addedAt;

  CartItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id']?.toInt(),
      productId: map['product_id']?.toString() ?? '0',
      productName: map['product_name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
      imageUrl: map['image_url'] ?? '',
      addedAt: DateTime.parse(map['added_at']),
    );
  }

  double get totalPrice => price * quantity;

  CartItem copyWith({
    int? id,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    String? imageUrl,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class Category {
  final int? id;
  final String name;
  final String imageUrl;
  final String? description;
  final bool featured;
  final String? color;

  Category({
    this.id,
    required this.name,
    required this.imageUrl,
    this.description,
    this.featured = false,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'featured': featured ? 1 : 0,
      'color': color,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      description: map['description'],
      featured: (map['featured'] == 1),
      color: map['color'],
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toInt(),
      name: json['name'] ?? json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      description: json['description'],
      featured: json['featured'] ?? false,
      color: json['color'],
    );
  }
}

class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String role;

  User({
    this.id,
    String? firstName,
    String? lastName,
    required this.email,
    String? phoneNumber,
    this.address,
    this.city,
    this.postalCode,
    this.profileImageUrl,
    DateTime? createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.role = 'customer',
    String?
    name, // Backward compatibility - will be split into firstName/lastName
    String? phone, // Backward compatibility - maps to phoneNumber
  }) : firstName = _extractFirstName(firstName, name),
       lastName = _extractLastName(lastName, name),
       phoneNumber = phoneNumber ?? phone,
       createdAt = createdAt ?? DateTime.now();

  static String _extractFirstName(String? firstName, String? name) {
    if (firstName != null && firstName.isNotEmpty) return firstName;
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      return parts.isNotEmpty ? parts.first : '';
    }
    return '';
  }

  static String _extractLastName(String? lastName, String? name) {
    if (lastName != null && lastName.isNotEmpty) return lastName;
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      return parts.length > 1 ? parts.skip(1).join(' ') : '';
    }
    return '';
  }

  String get fullName => '$firstName $lastName';
  String get name => fullName; // Backward compatibility getter

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': fullName, // Use single name field to match database schema
      'email': email,
      'phone': phoneNumber, // Map phoneNumber to phone field
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      // Note: Database doesn't have separate first_name/last_name columns
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      name: map['name'] ?? '', // Use single name field from database
      email: map['email'] ?? '',
      phone: map['phone'], // Map phone field to phoneNumber
      address: map['address'],
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'])
              : DateTime.now(),
      isActive: (map['is_active'] == 1),
      role: 'customer', // Default role since not stored in this table
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toInt(),
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postalCode'] ?? json['postal_code'],
      profileImageUrl: json['profileImageUrl'] ?? json['profile_image_url'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      lastLoginAt:
          json['lastLoginAt'] != null
              ? DateTime.parse(json['lastLoginAt'])
              : null,
      isActive:
          json['isActive'] is bool
              ? json['isActive']
              : (json['is_active'] == 1 || json['isActive'] == 1),
      role: json['role'] ?? 'customer',
    );
  }
}

class Order {
  final int? id;
  final int userId;
  final double totalAmount;
  final String status;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final List<OrderItem> items;

  Order({
    this.id,
    required this.userId,
    required this.totalAmount,
    this.status = 'pending',
    this.deliveryAddress,
    this.deliveryInstructions,
    DateTime? orderDate,
    this.deliveryDate,
    this.items = const [],
  }) : orderDate = orderDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'status': status,
      'delivery_address': deliveryAddress,
      'delivery_instructions': deliveryInstructions,
      'order_date': orderDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      deliveryAddress: map['delivery_address'],
      deliveryInstructions: map['delivery_instructions'],
      orderDate: DateTime.parse(map['order_date']),
      deliveryDate:
          map['delivery_date'] != null
              ? DateTime.parse(map['delivery_date'])
              : null,
      items: [], // Items would be loaded separately
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toInt(),
      orderId: map['order_id']?.toInt() ?? 0,
      productId: map['product_id']?.toString() ?? '0',
      productName: map['product_name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
    );
  }

  double get totalPrice => price * quantity;
}

class CartPersistent {
  final int? id;
  final int? userId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;
  final DateTime addedAt;

  CartPersistent({
    this.id,
    this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory CartPersistent.fromMap(Map<String, dynamic> map) {
    return CartPersistent(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt(),
      productId: map['product_id']?.toString() ?? '0',
      productName: map['product_name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
      imageUrl: map['image_url'] ?? '',
      addedAt: DateTime.parse(map['added_at']),
    );
  }

  double get totalPrice => price * quantity;
}
