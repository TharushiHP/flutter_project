import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class AuthService {
  static const String _baseUrl =
      'https://web-production-6d61b.up.railway.app'; // Your SSP API URL
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Jetstream Authentication
  Future<Map<String, dynamic>> loginWithJetstream(
    String email,
    String password,
  ) async {
    try {
      // First, get CSRF token
      final csrfResponse = await http.get(
        Uri.parse('$_baseUrl/sanctum/csrf-cookie'),
        headers: {'Accept': 'application/json'},
      );

      // Extract cookies for session
      String? cookies = csrfResponse.headers['set-cookie'];

      // Login request
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          if (cookies != null) 'Cookie': cookies,
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Get user data
        final userResponse = await http.get(
          Uri.parse('$_baseUrl/api/user'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${_extractToken(response)}',
            if (cookies != null) 'Cookie': cookies,
          },
        );

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          final token =
              _extractToken(response) ?? _extractSessionToken(cookies);

          // Save to local storage
          await _saveAuthData(token, userData);

          // Save to local database
          final user = User.fromJson(userData);
          await _dbHelper.insertUser(user);

          return {
            'success': true,
            'user': userData,
            'token': token,
            'message': 'Login successful',
          };
        }
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Login failed',
        'errors': errorData['errors'] ?? {},
      };
    } catch (e) {
      debugPrint('Jetstream login error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> registerWithJetstream(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      // Get CSRF token
      final csrfResponse = await http.get(
        Uri.parse('$_baseUrl/sanctum/csrf-cookie'),
        headers: {'Accept': 'application/json'},
      );

      String? cookies = csrfResponse.headers['set-cookie'];

      // Register request
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          if (cookies != null) 'Cookie': cookies,
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Get user data after registration
        final userResponse = await http.get(
          Uri.parse('$_baseUrl/api/user'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${_extractToken(response)}',
            if (cookies != null) 'Cookie': cookies,
          },
        );

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          final token =
              _extractToken(response) ?? _extractSessionToken(cookies);

          // Save to local storage
          await _saveAuthData(token, userData);

          // Save to local database
          final user = User.fromJson(userData);
          await _dbHelper.insertUser(user);

          return {
            'success': true,
            'user': userData,
            'token': token,
            'message': 'Registration successful',
          };
        }
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Registration failed',
        'errors': errorData['errors'] ?? {},
      };
    } catch (e) {
      debugPrint('Jetstream registration error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<bool> logoutFromJetstream() async {
    try {
      final token = await getStoredToken();
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Clear local storage
      await clearAuthData();
      return true;
    } catch (e) {
      debugPrint('Jetstream logout error: $e');
      // Clear local storage even if network request fails
      await clearAuthData();
      return true;
    }
  }

  // Firebase fallback authentication (for demo/testing)
  Future<Map<String, dynamic>> loginWithFirebase(
    String email,
    String password,
  ) async {
    try {
      // Implement Firebase authentication here
      // This is a placeholder for Firebase integration
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      if (email == 'demo@grocery.com' && password == 'password123') {
        final userData = {
          'id': 1,
          'name': 'Demo User',
          'email': email,
          'phone': '+1234567890',
          'address': '123 Demo Street',
        };

        await _saveAuthData('demo_token', userData);

        final user = User.fromJson(userData);
        await _dbHelper.insertUser(user);

        return {
          'success': true,
          'user': userData,
          'token': 'demo_token',
          'message': 'Demo login successful',
        };
      }

      if (email == 'mart@gmail.com' && password == 'password') {
        final userData = {
          'id': 3,
          'name': 'Mart User',
          'email': email,
          'phone': '+1122334455',
          'address': '789 Mart Street',
        };

        await _saveAuthData('mart_token', userData);

        final user = User.fromJson(userData);
        await _dbHelper.insertUser(user);

        return {
          'success': true,
          'user': userData,
          'token': 'mart_token',
          'message': 'Mart login successful',
        };
      }

      return {'success': false, 'message': 'Invalid credentials'};
    } catch (e) {
      return {'success': false, 'message': 'Firebase authentication error: $e'};
    }
  }

  Future<Map<String, dynamic>> registerWithFirebase(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Implement Firebase registration here
      await Future.delayed(const Duration(seconds: 1));

      final userData = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': name,
        'email': email,
        'phone': '',
        'address': '',
      };

      await _saveAuthData('firebase_token_${userData['id']}', userData);

      final user = User.fromJson(userData);
      await _dbHelper.insertUser(user);

      return {
        'success': true,
        'user': userData,
        'token': 'firebase_token_${userData['id']}',
        'message': 'Registration successful',
      };
    } catch (e) {
      return {'success': false, 'message': 'Firebase registration error: $e'};
    }
  }

  // Check authentication status
  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        debugPrint('Loading user data: $userData');
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Private helper methods
  Future<void> _saveAuthData(
    String? token,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  String? _extractToken(http.Response response) {
    // Try to extract token from response body
    try {
      final data = jsonDecode(response.body);
      return data['token'] ?? data['access_token'];
    } catch (e) {
      return null;
    }
  }

  String? _extractSessionToken(String? cookies) {
    // Extract session token from cookies for session-based auth
    if (cookies == null) return null;

    final sessionMatch = RegExp(r'laravel_session=([^;]+)').firstMatch(cookies);
    return sessionMatch?.group(1);
  }

  // API helper methods with authentication
  Future<http.Response> authenticatedGet(String endpoint) async {
    final token = await getStoredToken();
    return await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = await getStoredToken();
    return await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  Future<http.Response> authenticatedPut(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final token = await getStoredToken();
    return await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  Future<http.Response> authenticatedDelete(String endpoint) async {
    final token = await getStoredToken();
    return await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  // Validate token with server
  Future<bool> validateToken() async {
    try {
      final response = await authenticatedGet('/api/user');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Refresh token if needed
  Future<String?> refreshToken() async {
    try {
      final response = await authenticatedPost('/api/refresh', {});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] ?? data['access_token'];
        if (newToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newToken);
          return newToken;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return null;
    }
  }

  // Local SQLite authentication methods for MAD assignment
  Future<User?> authenticateLocal(String email, String password) async {
    try {
      if (kIsWeb) {
        // Web platform: Use SharedPreferences with hardcoded demo credentials
        // Check hardcoded demo credentials first
        if (email == 'demo@grocery.com' && password == 'password123') {
          return User(
            id: 1,
            name: 'Demo User',
            email: email,
            phone: '+1234567890',
            address: '123 Demo Street',
            createdAt: DateTime.now(),
            isActive: true,
          );
        }

        if (email == 'mart@gmail.com' && password == 'password') {
          return User(
            id: 3,
            name: 'Mart User',
            email: email,
            phone: '+1122334455',
            address: '789 Mart Street',
            createdAt: DateTime.now(),
            isActive: true,
          );
        }

        if (email == 'test@grocery.com' && password == 'password123') {
          return User(
            id: 2,
            name: 'Test User',
            email: email,
            phone: '+0987654321',
            address: '456 Test Avenue',
            createdAt: DateTime.now(),
            isActive: true,
          );
        }

        // Then check stored users in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString('users') ?? '[]';
        final List<dynamic> users = jsonDecode(usersJson);

        for (var userData in users) {
          if (userData['email'] == email) {
            return User.fromJson(userData);
          }
        }
        return null;
      } else {
        // Mobile platform: Use SQLite database
        final user = await _dbHelper.getUserByEmail(email);
        return user;
      }
    } catch (e) {
      debugPrint('Local authentication error: $e');
      return null;
    }
  }

  Future<User?> registerLocal(
    String name,
    String email,
    String password,
  ) async {
    try {
      if (kIsWeb) {
        // Web platform: Use SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString('users') ?? '[]';
        final List<dynamic> users = jsonDecode(usersJson);

        // Check if user already exists
        for (var userData in users) {
          if (userData['email'] == email) {
            throw Exception('User already exists with this email');
          }
        }

        // Create new user
        final userId = DateTime.now().millisecondsSinceEpoch;
        final user = User(
          id: userId,
          name: name,
          email: email,
          phone: '',
          address: '',
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Add to users list and save
        users.add(user.toMap());
        await prefs.setString('users', jsonEncode(users));

        return user;
      } else {
        // Mobile platform: Use SQLite database
        debugPrint(
          'AuthService: Checking for existing user with email: $email',
        );
        final existingUser = await _dbHelper.getUserByEmail(email);
        if (existingUser != null) {
          debugPrint('AuthService: User already exists with email: $email');
          throw Exception('User already exists with this email');
        }

        debugPrint('AuthService: Creating new user');
        final user = User(
          name: name,
          email: email,
          phone: '',
          address: '',
          createdAt: DateTime.now(),
          isActive: true,
        );

        debugPrint('AuthService: Inserting user into database');
        final userId = await _dbHelper.insertUser(user);
        debugPrint('AuthService: User inserted with ID: $userId');

        return User(
          id: userId,
          name: name,
          email: email,
          phone: '',
          address: '',
          createdAt: DateTime.now(),
          isActive: true,
        );
      }
    } catch (e) {
      debugPrint('Local registration error: $e');
      return null;
    }
  }

  // Create demo users for testing
  Future<void> createDemoUsers() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString('users') ?? '[]';
        final List<dynamic> users = jsonDecode(usersJson);

        // Only create demo users if none exist
        if (users.isEmpty) {
          final demoUsers = [
            {
              'id': 1,
              'name': 'Demo User',
              'email': 'demo@grocery.com',
              'phone': '+1234567890',
              'address': '123 Demo Street',
              'created_at': DateTime.now().toIso8601String(),
              'is_active': 1,
            },
            {
              'id': 2,
              'name': 'Test User',
              'email': 'test@grocery.com',
              'phone': '+0987654321',
              'address': '456 Test Avenue',
              'created_at': DateTime.now().toIso8601String(),
              'is_active': 1,
            },
            {
              'id': 3,
              'name': 'Mart User',
              'email': 'mart@gmail.com',
              'phone': '+1122334455',
              'address': '789 Mart Street',
              'created_at': DateTime.now().toIso8601String(),
              'is_active': 1,
            },
          ];

          await prefs.setString('users', jsonEncode(demoUsers));
          debugPrint('Demo users created for web platform');
        }
      }
      // For mobile, demo users will be created through normal database operations
    } catch (e) {
      debugPrint('Error creating demo users: $e');
    }
  }

  Future<void> saveUserToStorage(User user) async {
    final userData = user.toMap();
    await _saveAuthData('local_token_${user.id}', userData);
  }
}
