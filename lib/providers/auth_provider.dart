import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Authentication Provider for Fresh Grocery App
///
/// This app uses LOCAL AUTHENTICATION by default since the backend API
/// at web-production-6d61b.up.railway.app only provides product data,
/// not authentication endpoints.
///
/// User accounts are stored in local SQLite database for:
/// - Registration
/// - Login
/// - User profiles
/// - Preferences
///
/// Product data is fetched from the Railway API for demo purposes.

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  // Laravel API integration
  final ApiService _apiService = apiService;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  ApiUser? _apiUser; // Laravel API user
  String? _token;
  String? _errorMessage;
  bool _isLoading = false;
  bool _useApi = true; // Enable API mode to test Laravel endpoints

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  ApiUser? get apiUser => _apiUser;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get useApi => _useApi;

  // Toggle between API and local authentication
  void setAuthMode({required bool useApi}) {
    _useApi = useApi;

    // IMPORTANT: Notify DataProvider about data source change
    // This is handled by the UI layer that has access to both providers
    notifyListeners();
  }

  // Initialize authentication state
  Future<void> initializeAuth() async {
    _setLoading(true);

    try {
      if (_useApi) {
        // Initialize Laravel API authentication
        await _initializeApiAuth();
      } else {
        // Initialize local authentication (fallback)
        await _initializeLocalAuth();
      }

      debugPrint('Auth initialized: ${_status.toString()} (API: $_useApi)');
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _status = AuthStatus.unauthenticated;
      _user = null;
      _apiUser = null;
      _token = null;
    }

    _setLoading(false);
  }

  // Initialize Laravel API authentication
  Future<void> _initializeApiAuth() async {
    try {
      // Load stored authentication from API service
      await _apiService.loadStoredAuth();

      if (_apiService.isAuthenticated) {
        // Verify token is still valid by fetching current user
        final response = await _apiService.getCurrentUser();

        if (response.success && response.data != null) {
          _apiUser = response.data!;
          _token = _apiService.currentToken;
          _status = AuthStatus.authenticated;

          // Convert API user to local user format for compatibility
          _user = User(
            id: _apiUser!.id,
            firstName: _apiUser!.name.split(' ').first,
            lastName:
                _apiUser!.name.split(' ').length > 1
                    ? _apiUser!.name.split(' ').last
                    : '',
            email: _apiUser!.email,
            createdAt: DateTime.parse(_apiUser!.createdAt),
            isActive: true,
            role: 'customer',
          );
        } else {
          // Token invalid, clear auth
          await _apiService.clearAuth();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('API auth initialization error: $e');
      _status = AuthStatus.unauthenticated;
    }
  }

  // Initialize local authentication (fallback)
  Future<void> _initializeLocalAuth() async {
    try {
      // Create demo users for testing (web platform)
      await _authService.createDemoUsers();

      // Check if user is authenticated with timeout
      final isAuth = await _authService.isAuthenticated().timeout(
        Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Auth check timeout, assuming unauthenticated');
          return false;
        },
      );

      if (isAuth) {
        _user = await _authService.getCurrentUser();
        _token = await _authService.getStoredToken();

        if (_user != null && _token != null) {
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Local auth initialization error: $e');
      _status = AuthStatus.unauthenticated;
    }
  }

  // Login with Laravel API
  Future<bool> loginWithApi(String email, String password) async {
    return await _performAuth(() async {
      final response = await _apiService.login(email, password);

      if (response.success && response.user != null) {
        _apiUser = response.user!;
        _token = response.token;

        // Convert API user to local user format for compatibility
        _user = User(
          id: _apiUser!.id,
          firstName: _apiUser!.name.split(' ').first,
          lastName:
              _apiUser!.name.split(' ').length > 1
                  ? _apiUser!.name.split(' ').last
                  : '',
          email: _apiUser!.email,
          createdAt: DateTime.parse(_apiUser!.createdAt),
          isActive: true,
          role: 'customer',
        );

        _status = AuthStatus.authenticated;
        _clearError();

        debugPrint('API login successful for: ${_apiUser!.email}');
        return true;
      } else {
        _setError(response.message ?? 'Login failed');
        return false;
      }
    });
  }

  // Register with Laravel API
  Future<bool> registerWithApi(
    String name,
    String email,
    String password,
  ) async {
    return await _performAuth(() async {
      final response = await _apiService.register(name, email, password);

      if (response.success && response.user != null) {
        _apiUser = response.user!;
        _token = response.token;

        // Convert API user to local user format for compatibility
        _user = User(
          id: _apiUser!.id,
          firstName: _apiUser!.name.split(' ').first,
          lastName:
              _apiUser!.name.split(' ').length > 1
                  ? _apiUser!.name.split(' ').last
                  : '',
          email: _apiUser!.email,
          createdAt: DateTime.parse(_apiUser!.createdAt),
          isActive: true,
          role: 'customer',
        );

        _status = AuthStatus.authenticated;
        _clearError();

        debugPrint('API registration successful for: ${_apiUser!.email}');
        return true;
      } else {
        _setError(response.message ?? 'Registration failed');
        return false;
      }
    });
  }

  // Login with Jetstream
  Future<bool> loginWithJetstream(String email, String password) async {
    return await _performAuth(() async {
      final result = await _authService.loginWithJetstream(email, password);
      return _handleAuthResult(result);
    });
  }

  // Register with Jetstream
  Future<bool> registerWithJetstream(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    return await _performAuth(() async {
      final result = await _authService.registerWithJetstream(
        name,
        email,
        password,
        passwordConfirmation,
      );
      return _handleAuthResult(result);
    });
  }

  // Firebase fallback methods
  Future<bool> loginWithFirebase(String email, String password) async {
    return await _performAuth(() async {
      final result = await _authService.loginWithFirebase(email, password);
      return _handleAuthResult(result);
    });
  }

  Future<bool> registerWithFirebase(
    String name,
    String email,
    String password,
  ) async {
    return await _performAuth(() async {
      final result = await _authService.registerWithFirebase(
        name,
        email,
        password,
      );
      return _handleAuthResult(result);
    });
  }

  // Demo login for testing
  Future<bool> loginDemo() async {
    return await loginWithFirebase('demo@grocery.com', 'password123');
  }

  // Main authentication methods (choose between API and local)
  Future<bool> login(String email, String password) async {
    if (_useApi) {
      return await loginWithApi(email, password);
    } else {
      // Use local database authentication for MAD assignment
      return await loginLocal(email, password);
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String? passwordConfirmation,
  }) async {
    if (_useApi) {
      return await registerWithApi(name, email, password);
    } else {
      // Use local database registration for MAD assignment
      return await registerLocal(name, email, password);
    }
  }

  // Local authentication using SQLite database
  Future<bool> loginLocal(String email, String password) async {
    return await _performAuth(() async {
      try {
        final user = await _authService.authenticateLocal(email, password);
        if (user != null) {
          _user = user;
          _token = 'local_token_${user.id}';
          _status = AuthStatus.authenticated;
          await _authService.saveUserToStorage(user);
          return true;
        }
        return false;
      } catch (e) {
        debugPrint('Local login error: $e');
        return false;
      }
    });
  }

  Future<bool> registerLocal(String name, String email, String password) async {
    return await _performAuth(() async {
      try {
        debugPrint('AuthProvider: Starting local registration for $email');
        final user = await _authService.registerLocal(name, email, password);
        if (user != null) {
          debugPrint('AuthProvider: Local registration successful');
          _user = user;
          _token = 'local_token_${user.id}';
          _status = AuthStatus.authenticated;
          await _authService.saveUserToStorage(user);
          _clearError();
          return true;
        } else {
          debugPrint('AuthProvider: Local registration returned null user');
          _setError('Registration failed - could not create user');
          return false;
        }
      } catch (e) {
        debugPrint('AuthProvider: Local registration error: $e');
        _setError('Registration failed: $e');
        return false;
      }
    });
  }

  // Logout (supports both API and local auth)
  Future<void> logout() async {
    _setLoading(true);

    try {
      if (_useApi && _apiService.isAuthenticated) {
        // Logout from Laravel API
        await _apiService.logout();
        _apiUser = null;
      } else {
        // Logout from local/Jetstream
        await _authService.logoutFromJetstream();
      }

      // Clear all local state
      _user = null;
      _token = null;
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;

      debugPrint('Logout successful (API: $_useApi)');
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear local state even if server logout fails
      _user = null;
      _apiUser = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
    }

    _setLoading(false);
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    _setLoading(true);

    try {
      final response = await _authService.authenticatedPut(
        '/api/user',
        userData,
      );

      if (response.statusCode == 200) {
        final updatedUserData = Map<String, dynamic>.from(userData);
        updatedUserData['id'] = _user?.id;
        _user = User.fromJson(updatedUserData);

        _clearError();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update profile');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);

    try {
      final response = await _authService
          .authenticatedPut('/api/user/password', {
            'current_password': currentPassword,
            'password': newPassword,
            'password_confirmation': newPassword,
          });

      if (response.statusCode == 200) {
        _clearError();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to change password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);

    try {
      final response = await _authService.authenticatedPost(
        '/api/forgot-password',
        {'email': email},
      );

      if (response.statusCode == 200) {
        _clearError();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to send reset email');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Refresh current user data
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    try {
      final response = await _authService.authenticatedGet('/api/user');
      if (response.statusCode == 200) {
        final userData = Map<String, dynamic>.from(
          Map<String, dynamic>.from(response.body as Map),
        );
        _user = User.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  // Validate current session
  Future<bool> validateSession() async {
    if (!isAuthenticated) return false;

    try {
      final isValid = await _authService.validateToken();
      if (!isValid) {
        await logout();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Session validation error: $e');
      await logout();
      return false;
    }
  }

  // Private helper methods
  Future<bool> _performAuth(Future<bool> Function() authFunction) async {
    _setLoading(true);
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final success = await authFunction();
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Authentication error: $e');
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      return false;
    }
  }

  bool _handleAuthResult(Map<String, dynamic> result) {
    if (result['success'] == true) {
      _user = User.fromJson(result['user']);
      _token = result['token'];
      _status = AuthStatus.authenticated;
      _clearError();
      return true;
    } else {
      _setError(result['message'] ?? 'Authentication failed');
      _status = AuthStatus.unauthenticated;
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message manually
  void clearError() {
    _clearError();
  }

  // Get authentication headers for API calls
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Check if user has specific role or permission
  bool hasRole(String role) {
    final email = _user?.email;
    return email != null && email.contains('admin');
  }

  bool hasPermission(String permission) {
    // Implement permission checking logic based on your needs
    return isAuthenticated;
  }

  // Legacy getters for backward compatibility
  String? get userEmail => _user?.email;
  String? get userName => _user?.name;
}
