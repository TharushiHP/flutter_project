import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';

/// Comprehensive API service for Laravel backend integration
/// Handles authentication with Jetstream/Fortify and all API communications
///
/// Usage:
/// ```dart
/// final apiService = ApiService();
/// final response = await apiService.login('user@example.com', 'password');
/// if (response.success) {
///   // Authentication successful, token saved automatically
///   final user = response.user!;
/// }
/// ```
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Laravel backend base URL hosted on Railway
  static const String _baseUrl = 'https://web-production-6d61b.up.railway.app';
  static const String _apiPrefix = '/api';

  // Storage keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  // HTTP client instance
  final http.Client _client = http.Client();

  // Cached token and user data
  String? _cachedToken;
  ApiUser? _cachedUser;

  // Cached API data to prevent redundant calls
  List<Map<String, dynamic>>? _cachedProducts;
  List<Map<String, dynamic>>? _cachedCategories;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Check if cached data is still valid
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration;
  }

  /// Clear cached data
  void clearCache() {
    _cachedProducts = null;
    _cachedCategories = null;
    _cacheTimestamp = null;
  }

  /// Get the full API URL for an endpoint
  /// Example: _getApiUrl('/login') returns 'https://web-production-6d61b.up.railway.app/api/login'
  String _getApiUrl(String endpoint) {
    return '$_baseUrl$_apiPrefix$endpoint';
  }

  /// Get common headers for API requests
  /// Includes Content-Type and Authorization if token is available
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _cachedToken != null) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }

    return headers;
  }

  /// Load stored authentication token from SharedPreferences
  /// Call this method on app startup to restore authentication state
  Future<void> loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);

      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _cachedUser = ApiUser.fromJson(userMap);
      }

      debugPrint(
        'ApiService: Loaded stored auth - Token: ${_cachedToken != null}, User: ${_cachedUser?.email}',
      );
    } catch (e) {
      debugPrint('ApiService: Error loading stored auth: $e');
      _cachedToken = null;
      _cachedUser = null;
    }
  }

  /// Save authentication data to SharedPreferences
  Future<void> _saveAuth(String token, ApiUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, json.encode(user.toJson()));

      _cachedToken = token;
      _cachedUser = user;

      debugPrint('ApiService: Saved auth for user: ${user.email}');
    } catch (e) {
      debugPrint('ApiService: Error saving auth: $e');
      throw ApiException(message: 'Failed to save authentication data');
    }
  }

  /// Clear stored authentication data (for logout)
  Future<void> clearAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);

      _cachedToken = null;
      _cachedUser = null;

      debugPrint('ApiService: Cleared authentication data');
    } catch (e) {
      debugPrint('ApiService: Error clearing auth: $e');
    }
  }

  /// Check if user is currently authenticated (has valid token)
  bool get isAuthenticated => _cachedToken != null && _cachedUser != null;

  /// Get current authenticated user (cached)
  ApiUser? get currentUser => _cachedUser;

  /// Get current auth token (cached)
  String? get currentToken => _cachedToken;

  /// Login user with email and password
  ///
  /// Usage:
  /// ```dart
  /// final response = await apiService.login('user@example.com', 'password123');
  /// if (response.success) {
  ///   debugPrint('Welcome ${response.user!.name}');
  /// } else {
  ///   debugPrint('Login failed: ${response.message}');
  /// }
  /// ```
  Future<AuthResponse> login(String email, String password) async {
    try {
      debugPrint('ApiService: Attempting login for $email');

      final response = await _client
          .post(
            Uri.parse(_getApiUrl('/login')),
            headers: _getHeaders(includeAuth: false),
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('ApiService: Login response status: ${response.statusCode}');
      debugPrint('ApiService: Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Handle Laravel's new response format: {"success": true, "data": {"user": {...}, "token": "..."}}
        if (responseData['success'] == true &&
            responseData.containsKey('data')) {
          final data = responseData['data'] as Map<String, dynamic>;

          if (data.containsKey('token') && data.containsKey('user')) {
            final token = data['token'] as String;
            final userData = data['user'] as Map<String, dynamic>;
            final user = ApiUser.fromJson(userData);

            await _saveAuth(token, user);

            return AuthResponse.success(
              token: token,
              user: user,
              message: responseData['message'] ?? 'Login successful',
            );
          }
        }

        // Fallback for old format (direct token/user in response)
        if (responseData.containsKey('token') &&
            responseData.containsKey('user')) {
          final token = responseData['token'] as String;
          final userData = responseData['user'] as Map<String, dynamic>;
          final user = ApiUser.fromJson(userData);

          await _saveAuth(token, user);

          return AuthResponse.success(
            token: token,
            user: user,
            message: 'Login successful',
          );
        }

        return AuthResponse.error(
          message: 'Invalid response format from Laravel API',
        );
      } else if (response.statusCode == 401) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return AuthResponse.error(
          message: responseData['message'] ?? 'Invalid email or password',
        );
      } else if (response.statusCode == 405) {
        // Method Not Allowed - Laravel route not properly configured
        return AuthResponse.error(
          message:
              'Laravel login endpoint not configured. Using local authentication instead.',
        );
      } else if (response.statusCode == 422) {
        // Validation errors
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return AuthResponse.error(
          message: responseData['message'] ?? 'Validation failed',
          errors: responseData['errors'] as Map<String, dynamic>?,
        );
      } else {
        return AuthResponse.error(
          message:
              'Laravel API login failed (${response.statusCode}). Using local authentication.',
        );
      }
    } on SocketException {
      return AuthResponse.error(
        message: 'No internet connection. Using local authentication.',
      );
    } on http.ClientException catch (e) {
      debugPrint('ApiService: HTTP client error during login: $e');
      return AuthResponse.error(
        message:
            'Connection to Laravel API failed. Using local authentication.',
      );
    } catch (e) {
      debugPrint('ApiService: Login error: $e');
      return AuthResponse.error(
        message:
            'Laravel API temporarily unavailable. Using local authentication.',
      );
    }
  }

  /// Register new user with name, email, and password
  ///
  /// Usage:
  /// ```dart
  /// final response = await apiService.register('John Doe', 'john@example.com', 'password123');
  /// if (response.success) {
  ///   debugPrint('Registration successful for ${response.user!.name}');
  /// } else {
  ///   debugPrint('Registration failed: ${response.message}');
  /// }
  /// ```
  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      debugPrint('ApiService: Attempting registration for $email');

      final response = await _client.post(
        Uri.parse(_getApiUrl('/register')),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password, // Laravel requirement
        }),
      );

      debugPrint(
        'ApiService: Registration response status: ${response.statusCode}',
      );
      debugPrint('ApiService: Registration response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Handle Laravel's new response format: {"success": true, "data": {"user": {...}, "token": "..."}}
        if (responseData['success'] == true &&
            responseData.containsKey('data')) {
          final data = responseData['data'] as Map<String, dynamic>;

          if (data.containsKey('token') && data.containsKey('user')) {
            final token = data['token'] as String;
            final userData = data['user'] as Map<String, dynamic>;
            final user = ApiUser.fromJson(userData);

            await _saveAuth(token, user);

            return AuthResponse.success(
              token: token,
              user: user,
              message: responseData['message'] ?? 'Registration successful',
            );
          }
        }

        // Fallback for old format (direct token/user in response)
        if (responseData.containsKey('token') &&
            responseData.containsKey('user')) {
          final token = responseData['token'] as String;
          final userData = responseData['user'] as Map<String, dynamic>;
          final user = ApiUser.fromJson(userData);

          await _saveAuth(token, user);

          return AuthResponse.success(
            token: token,
            user: user,
            message: 'Registration successful',
          );
        } else {
          return AuthResponse.error(
            message: 'Invalid response format from server',
          );
        }
      } else if (response.statusCode == 405) {
        // Method Not Allowed - Laravel registration endpoint not configured
        return AuthResponse.error(
          message:
              'Laravel registration endpoint not configured. Using local registration instead.',
        );
      } else if (response.statusCode == 422) {
        // Validation errors (email already exists, etc.)
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return AuthResponse.error(
          message: 'Registration validation failed',
          errors: responseData['errors'] as Map<String, dynamic>?,
        );
      } else {
        return AuthResponse.error(
          message: 'Registration failed with status ${response.statusCode}',
        );
      }
    } on SocketException {
      return AuthResponse.error(message: 'No internet connection');
    } catch (e) {
      debugPrint('ApiService: Registration error: $e');
      return AuthResponse.error(message: 'Registration failed: $e');
    }
  }

  /// Get current user information from server (using stored token)
  /// This verifies the token is still valid and refreshes user data
  ///
  /// Usage:
  /// ```dart
  /// final response = await apiService.getCurrentUser();
  /// if (response.success) {
  ///   final user = response.data!;
  ///   debugPrint('Current user: ${user.name}');
  /// }
  /// ```
  Future<ApiResponse<ApiUser>> getCurrentUser() async {
    if (_cachedToken == null) {
      return ApiResponse.error(message: 'No authentication token available');
    }

    try {
      debugPrint('ApiService: Fetching current user info');

      final response = await _client.get(
        Uri.parse(_getApiUrl('/user')),
        headers: _getHeaders(),
      );

      debugPrint(
        'ApiService: Get user response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final user = ApiUser.fromJson(responseData);

        // Update cached user data
        _cachedUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(user.toJson()));

        return ApiResponse.success(data: user, message: 'User data fetched');
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await clearAuth();
        return ApiResponse.error(
          message: 'Authentication expired, please login again',
          statusCode: 401,
        );
      } else {
        return ApiResponse.error(
          message: 'Failed to fetch user data',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error(message: 'No internet connection');
    } catch (e) {
      debugPrint('ApiService: Get current user error: $e');
      return ApiResponse.error(message: 'Failed to fetch user: $e');
    }
  }

  /// Fetch list of all users (requires authentication)
  /// Useful for admin features or user management
  ///
  /// Usage:
  /// ```dart
  /// final response = await apiService.fetchUsers();
  /// if (response.success) {
  ///   final users = response.data!;
  ///   debugPrint('Found ${users.length} users');
  /// }
  /// ```
  Future<ApiResponse<List<ApiUser>>> fetchUsers() async {
    if (_cachedToken == null) {
      return ApiResponse.error(message: 'Authentication required');
    }

    try {
      debugPrint('ApiService: Fetching users list');

      final response = await _client.get(
        Uri.parse(_getApiUrl('/users')),
        headers: _getHeaders(),
      );

      debugPrint(
        'ApiService: Fetch users response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Handle both direct array and wrapped response formats
        List<dynamic> usersJson;
        if (responseData.containsKey('data')) {
          usersJson = responseData['data'] as List<dynamic>;
        } else if (responseData.containsKey('users')) {
          usersJson = responseData['users'] as List<dynamic>;
        } else {
          // Assume the response is directly an array
          usersJson = json.decode(response.body) as List<dynamic>;
        }

        final users =
            usersJson
                .map(
                  (userJson) =>
                      ApiUser.fromJson(userJson as Map<String, dynamic>),
                )
                .toList();

        return ApiResponse.success(
          data: users,
          message: 'Users fetched successfully',
        );
      } else if (response.statusCode == 401) {
        await clearAuth();
        return ApiResponse.error(
          message: 'Authentication expired, please login again',
          statusCode: 401,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse.error(
          message: 'Access denied - insufficient permissions',
          statusCode: 403,
        );
      } else {
        return ApiResponse.error(
          message: 'Failed to fetch users',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error(message: 'No internet connection');
    } catch (e) {
      debugPrint('ApiService: Fetch users error: $e');
      return ApiResponse.error(message: 'Failed to fetch users: $e');
    }
  }

  /// Logout user (optional: call logout endpoint on server)
  /// Clears local authentication data
  ///
  /// Usage:
  /// ```dart
  /// await apiService.logout();
  /// // User is now logged out locally
  /// ```
  Future<void> logout() async {
    try {
      if (_cachedToken != null) {
        debugPrint('ApiService: Logging out user');

        // Optional: Call server logout endpoint
        try {
          await _client.post(
            Uri.parse(_getApiUrl('/logout')),
            headers: _getHeaders(),
          );
        } catch (e) {
          debugPrint(
            'ApiService: Server logout failed (continuing with local logout): $e',
          );
        }
      }
    } finally {
      // Always clear local auth data
      await clearAuth();
    }
  }

  /// Test API connectivity
  /// Useful for checking if the Laravel backend is accessible
  ///
  /// Usage:
  /// ```dart
  /// final isConnected = await apiService.testConnection();
  /// if (!isConnected) {
  ///   debugPrint('Backend server is not accessible');
  /// }
  /// ```
  Future<bool> testConnection() async {
    try {
      debugPrint('ApiService: Testing connection to $_baseUrl');

      // Test basic Laravel homepage first (most reliable)
      final response = await _client
          .get(
            Uri.parse(_baseUrl), // Just test the main Laravel page
            headers: {'Accept': 'text/html,application/json'},
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('ApiService: Connection test status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService: Connection test failed: $e');
      return false;
    }
  }

  // ===============================================
  // HYBRID DATA METHODS - Products & Categories
  // ===============================================

  /// Fetch products from Laravel API
  /// Falls back to local database if API fails
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    // Return cached data if still valid
    if (_isCacheValid() && _cachedProducts != null) {
      debugPrint(
        'ApiService: Returning cached products (${_cachedProducts!.length} items)',
      );
      return _cachedProducts!;
    }

    try {
      debugPrint('ApiService: Fetching products from Laravel API...');

      final response = await _client
          .get(
            Uri.parse(_getApiUrl('/products')),
            headers: _getHeaders(includeAuth: false),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'ApiService: Products response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Handle the Laravel API response structure
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> products = jsonResponse['data']['products'] ?? [];
          debugPrint(
            'ApiService: Successfully fetched ${products.length} products from Laravel API',
          );

          // Convert Laravel API format to Flutter format
          final result =
              products
                  .map(
                    (item) => {
                      'id': item['id']?.toString() ?? '',
                      'name': item['name'] ?? '',
                      'price':
                          (item['price'] is String)
                              ? double.tryParse(item['price']) ?? 0.0
                              : (item['price'] ?? 0.0).toDouble(),
                      'category': item['category'] ?? '',
                      'description': item['description'] ?? '',
                      'image': item['image'] ?? '',
                      'stock': _parseQuantity(
                        item['quantity']?.toString() ?? '0',
                      ),
                      'rating': 4.5, // Default rating since not in API
                      'isOrganic': false, // Default value
                      'nutritionInfo': item['description'] ?? '',
                      'origin': 'Sri Lanka', // Default origin
                      'expiryDate': '', // Not provided by API
                      'created_at': item['created_at'] ?? '',
                      'updated_at': item['updated_at'] ?? '',
                    },
                  )
                  .toList();

          // Cache the products data
          _cachedProducts = result;
          _cacheTimestamp = DateTime.now();

          return result;
        } else {
          throw Exception('Invalid Laravel API response format');
        }
      } else {
        throw Exception(
          'Laravel API returned ${response.statusCode} - Products endpoint may be temporarily unavailable',
        );
      }
    } catch (e) {
      debugPrint('ApiService: Error fetching products from Laravel API: $e');
      rethrow; // Let caller handle fallback to local data
    }
  }

  /// Parse quantity string to integer (handles various formats like "1 kg", "500 g", etc.)
  int _parseQuantity(String quantity) {
    if (quantity.isEmpty) return 0;

    // Extract numbers from quantity string
    final RegExp numberRegex = RegExp(r'\d+');
    final match = numberRegex.firstMatch(quantity);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  /// Fetch categories from Laravel API
  /// Falls back to local database if API fails
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    // Return cached categories if still valid
    if (_isCacheValid() && _cachedCategories != null) {
      debugPrint(
        'ApiService: Returning cached categories (${_cachedCategories!.length} items)',
      );
      return _cachedCategories!;
    }

    try {
      debugPrint('ApiService: Fetching categories from API');

      // Use cached products if available, otherwise fetch fresh
      List<Map<String, dynamic>> products;
      if (_isCacheValid() && _cachedProducts != null) {
        debugPrint('ApiService: Using cached products for category extraction');
        products = _cachedProducts!;
      } else {
        products = await fetchProducts();
      }

      final Set<String> categoryNames =
          products
              .map((product) => product['category'] as String)
              .where((category) => category.isNotEmpty)
              .toSet();

      debugPrint(
        'ApiService: Extracted ${categoryNames.length} categories from products',
      );

      // Convert to format compatible with local Category model
      int idCounter = 1;
      final result =
          categoryNames
              .map(
                (categoryName) => {
                  'id': idCounter++, // Generate sequential integer IDs
                  'name': categoryName,
                  'description': 'Fresh $categoryName products',
                  'color': _getCategoryColor(categoryName),
                  'icon': _getCategoryIcon(categoryName),
                  'image_url': _getCategoryIcon(
                    categoryName,
                  ), // Add image_url for compatibility
                },
              )
              .toList();

      // Cache the categories data
      _cachedCategories = result;
      _cacheTimestamp = DateTime.now();

      // Debug print to see what we're returning
      debugPrint('ApiService: Category data being returned: $result');
      return result;
    } catch (e) {
      debugPrint('ApiService: Error fetching categories: $e');
      rethrow; // Let caller handle fallback to local data
    }
  }

  /// Get category color based on name
  String _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'vegetables':
        return 'green';
      case 'fruits':
        return 'orange';
      case 'dairy products':
      case 'dairy':
        return 'blue';
      case 'meat':
        return 'red';
      case 'grains':
        return 'brown';
      case 'bakery':
        return 'yellow';
      default:
        return 'grey';
    }
  }

  /// Get category icon based on name
  String _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'vegetables':
        return 'eco';
      case 'fruits':
        return 'local_florist';
      case 'dairy products':
      case 'dairy':
        return 'opacity';
      case 'meat':
        return 'restaurant';
      case 'grains':
        return 'grain';
      case 'bakery':
        return 'cake';
      default:
        return 'category';
    }
  }

  /// Fetch single product by ID from Laravel API
  Future<Map<String, dynamic>?> fetchProductById(String productId) async {
    try {
      debugPrint('ApiService: Fetching product $productId from API');

      final response = await _client
          .get(
            Uri.parse(_getApiUrl('/products/$productId')),
            headers: _getHeaders(includeAuth: false),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('ApiService: Successfully fetched product $productId');

        // Convert to format compatible with local Product model
        return {
          'id': data['id']?.toString() ?? '',
          'name': data['name'] ?? '',
          'price':
              (data['price'] is String)
                  ? double.tryParse(data['price']) ?? 0.0
                  : (data['price'] ?? 0.0).toDouble(),
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
          'image': data['image'] ?? '',
          'stock': data['stock'] ?? 0,
          'rating': (data['rating'] ?? 0.0).toDouble(),
          'isOrganic': data['is_organic'] == true || data['is_organic'] == 1,
          'nutritionInfo': data['nutrition_info'] ?? '',
          'origin': data['origin'] ?? '',
          'expiryDate': data['expiry_date'] ?? '',
        };
      } else if (response.statusCode == 404) {
        debugPrint('ApiService: Product $productId not found');
        return null;
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService: Error fetching product $productId: $e');
      return null; // Return null to indicate failure
    }
  }

  /// Check Laravel API health and connectivity
  /// Returns detailed status about API endpoints
  Future<Map<String, dynamic>> checkApiHealth() async {
    final healthStatus = <String, dynamic>{
      'isHealthy': false,
      'endpoints': <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Test health endpoint
      debugPrint('ApiService: Checking Laravel API health...');
      final healthResponse = await _client
          .get(
            Uri.parse(_getApiUrl('/health')),
            headers: _getHeaders(includeAuth: false),
          )
          .timeout(const Duration(seconds: 5));

      final endpoints = healthStatus['endpoints'] as Map<String, dynamic>;

      endpoints['health'] = {
        'status': healthResponse.statusCode,
        'working': healthResponse.statusCode == 200,
        'response':
            healthResponse.statusCode == 200
                ? json.decode(healthResponse.body)
                : healthResponse.body,
      };

      // Test products endpoint
      try {
        final productsResponse = await _client
            .get(
              Uri.parse(_getApiUrl('/products')),
              headers: _getHeaders(includeAuth: false),
            )
            .timeout(const Duration(seconds: 5));

        endpoints['products'] = {
          'status': productsResponse.statusCode,
          'working': productsResponse.statusCode == 200,
          'productCount':
              productsResponse.statusCode == 200
                  ? (json.decode(productsResponse.body)['data']['products']
                          as List)
                      .length
                  : 0,
        };
      } catch (e) {
        endpoints['products'] = {
          'status': 0,
          'working': false,
          'error': e.toString(),
        };
      }

      // Test login endpoint
      try {
        final loginResponse = await _client
            .post(
              Uri.parse(_getApiUrl('/login')),
              headers: _getHeaders(includeAuth: false),
              body: json.encode({
                'email': 'test@example.com',
                'password': 'test',
              }),
            )
            .timeout(const Duration(seconds: 5));

        endpoints['login'] = {
          'status': loginResponse.statusCode,
          'working':
              loginResponse.statusCode != 405 &&
              loginResponse.statusCode != 404,
          'note':
              loginResponse.statusCode == 405
                  ? 'Method Not Allowed - Route not configured'
                  : loginResponse.statusCode == 404
                  ? 'Endpoint not found'
                  : 'Available',
        };
      } catch (e) {
        endpoints['login'] = {
          'status': 0,
          'working': false,
          'error': e.toString(),
        };
      }

      // Determine overall health
      final workingEndpoints =
          endpoints.values
              .where(
                (endpoint) =>
                    (endpoint as Map<String, dynamic>)['working'] == true,
              )
              .length;

      healthStatus['isHealthy'] =
          workingEndpoints >= 2; // Health + Products = minimum viable
      healthStatus['workingEndpoints'] = workingEndpoints;
      healthStatus['totalEndpoints'] = 3;

      debugPrint(
        'ApiService: Health check complete - ${healthStatus['workingEndpoints']}/${healthStatus['totalEndpoints']} endpoints working',
      );
    } catch (e) {
      debugPrint('ApiService: Health check failed: $e');
      healthStatus['error'] = e.toString();
    }

    return healthStatus;
  }

  /// Dispose of resources (call when app is closing)
  void dispose() {
    _client.close();
  }
}

/// Singleton instance of ApiService for easy access throughout the app
///
/// Usage:
/// ```dart
/// import 'package:assignment/services/api_service.dart';
///
/// // In your widget or provider:
/// final response = await apiService.login(email, password);
/// ```
final ApiService apiService = ApiService();
