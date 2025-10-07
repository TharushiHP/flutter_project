/// API response models for Laravel backend integration
/// These models handle serialization/deserialization of data from the Laravel API

/// User model that matches Laravel User model structure
class ApiUser {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String createdAt;
  final String updatedAt;

  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ApiUser from JSON response (from Laravel API)
  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  /// Convert ApiUser to JSON (for sending to Laravel API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'ApiUser{id: $id, name: $name, email: $email}';
  }
}

/// Authentication response model for login/register endpoints
class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final ApiUser? user;
  final Map<String, dynamic>? errors;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
    this.errors,
  });

  /// Create AuthResponse from Laravel Fortify/Jetstream response
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      token: json['token'] as String?,
      user: json['user'] != null ? ApiUser.fromJson(json['user']) : null,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  /// Create success response
  factory AuthResponse.success({
    required String token,
    required ApiUser user,
    String? message,
  }) {
    return AuthResponse(
      success: true,
      token: token,
      user: user,
      message: message ?? 'Authentication successful',
    );
  }

  /// Create error response
  factory AuthResponse.error({
    required String message,
    Map<String, dynamic>? errors,
  }) {
    return AuthResponse(success: false, message: message, errors: errors);
  }

  @override
  String toString() {
    return 'AuthResponse{success: $success, message: $message, hasToken: ${token != null}, hasUser: ${user != null}}';
  }
}

/// Generic API response wrapper for other endpoints
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  /// Create success response with data
  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required String message,
    Map<String, dynamic>? errors,
    int? statusCode,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, statusCode: $statusCode}';
  }
}

/// Exception class for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({required this.message, this.statusCode, this.errors});

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}
