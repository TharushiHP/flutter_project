class Category {
  final String id;
  final String name;
  final String imageUrl;
  final String? description;
  final String? color;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description,
    this.color,
  });

  // Keep backward compatibility
  String get title => name;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      description: json['description'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'color': color,
    };
  }

  // Database Map methods for local database operations
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['title'] ?? '',
      imageUrl: map['image_url'] ?? map['imageUrl'] ?? '',
      description: map['description'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'color': color,
    };
  }
}
