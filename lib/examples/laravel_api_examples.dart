/// Example Usage Guide for Laravel API Integration
/// This file shows how to use the Laravel backend with Jetstream authentication
/// in your Flutter grocery store app.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Example 1: Login Screen with API Integration
class ApiExampleLoginScreen extends StatefulWidget {
  const ApiExampleLoginScreen({super.key});

  @override
  State<ApiExampleLoginScreen> createState() => _ApiExampleLoginScreenState();
}

class _ApiExampleLoginScreenState extends State<ApiExampleLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Laravel API Login')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Toggle between API and Local auth
                SwitchListTile(
                  title: Text('Use Laravel API'),
                  subtitle: Text(
                    authProvider.useApi
                        ? 'Using Laravel backend on Railway'
                        : 'Using local SQLite database',
                  ),
                  value: authProvider.useApi,
                  onChanged: (value) {
                    authProvider.setAuthMode(useApi: value);
                  },
                ),

                SizedBox(height: 20),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),

                SizedBox(height: 20),

                if (authProvider.isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      final success = await authProvider.login(
                        _emailController.text,
                        _passwordController.text,
                      );

                      if (success) {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/main');
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                authProvider.errorMessage ?? 'Login failed',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Text('Login'),
                  ),

                if (authProvider.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Example 2: Register Screen with API Integration
class ApiExampleRegisterScreen extends StatefulWidget {
  const ApiExampleRegisterScreen({super.key});

  @override
  State<ApiExampleRegisterScreen> createState() =>
      _ApiExampleRegisterScreenState();
}

class _ApiExampleRegisterScreenState extends State<ApiExampleRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Laravel API Registration')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                  ),
                ),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),

                SizedBox(height: 20),

                if (authProvider.isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      final success = await authProvider.register(
                        _nameController.text,
                        _emailController.text,
                        _passwordController.text,
                      );

                      if (success) {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/main');
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                authProvider.errorMessage ??
                                    'Registration failed',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Text('Register'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Example 3: Direct API Service Usage (without Provider)
class DirectApiExample {
  /// Example: Login directly with API service
  static Future<void> exampleDirectLogin() async {
    try {
      print('Testing Laravel API connection...');

      // Test connection first
      final isConnected = await apiService.testConnection();
      print('API Connection: ${isConnected ? 'Success' : 'Failed'}');

      if (!isConnected) {
        print(
          'Cannot reach Laravel backend at https://web-production-6d61b.up.railway.app',
        );
        return;
      }

      // Attempt login
      final response = await apiService.login(
        'user@example.com',
        'password123',
      );

      if (response.success) {
        print('Login successful!');
        print('User: ${response.user!.name} (${response.user!.email})');
        print('Token: ${response.token}');

        // Now you can use authenticated endpoints
        await exampleFetchUsers();
      } else {
        print('Login failed: ${response.message}');
        if (response.errors != null) {
          print('Validation errors: ${response.errors}');
        }
      }
    } catch (e) {
      print('Exception during login: $e');
    }
  }

  /// Example: Register new user
  static Future<void> exampleDirectRegister() async {
    try {
      final response = await apiService.register(
        'New User',
        'newuser@example.com',
        'password123',
      );

      if (response.success) {
        print('Registration successful!');
        print('User: ${response.user!.name}');
      } else {
        print('Registration failed: ${response.message}');
      }
    } catch (e) {
      print('Exception during registration: $e');
    }
  }

  /// Example: Fetch users (requires authentication)
  static Future<void> exampleFetchUsers() async {
    try {
      final response = await apiService.fetchUsers();

      if (response.success) {
        print('Found ${response.data!.length} users:');
        for (final user in response.data!) {
          print('- ${user.name} (${user.email})');
        }
      } else {
        print('Failed to fetch users: ${response.message}');

        if (response.statusCode == 401) {
          print('Authentication required. Please login first.');
        }
      }
    } catch (e) {
      print('Exception fetching users: $e');
    }
  }

  /// Example: Get current user info
  static Future<void> exampleGetCurrentUser() async {
    try {
      final response = await apiService.getCurrentUser();

      if (response.success) {
        final user = response.data!;
        debugPrint('Current user: ${user.name}');
        debugPrint('Email: ${user.email}');
        debugPrint('Joined: ${user.createdAt}');
      } else {
        debugPrint('Failed to get user info: ${response.message}');
      }
    } catch (e) {
      debugPrint('Exception getting current user: $e');
    }
  }
}

/// Example 4: Error Handling Best Practices
class ApiErrorHandlingExample {
  /// Comprehensive error handling for login
  static Future<String?> handleLoginWithErrors(
    String email,
    String password,
  ) async {
    try {
      // Test connection first
      final isConnected = await apiService.testConnection();
      if (!isConnected) {
        return 'Cannot connect to server. Please check your internet connection.';
      }

      final response = await apiService.login(email, password);

      if (response.success) {
        return null; // Success, no error
      } else {
        // Handle different types of errors
        if (response.errors != null) {
          // Validation errors from Laravel
          final errors = response.errors!;
          List<String> errorMessages = [];

          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessages.addAll(messages.cast<String>());
            }
          });

          return errorMessages.join(', ');
        } else {
          // General error message
          return response.message ?? 'Login failed';
        }
      }
    } catch (e) {
      // Network or other exceptions
      if (e.toString().contains('SocketException')) {
        return 'No internet connection available';
      } else if (e.toString().contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      } else {
        return 'Unexpected error: $e';
      }
    }
  }

  /// Show user-friendly error messages
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Example 5: Integration with your existing screens
/// 
/// To integrate with your existing login_screen.dart:
/// 
/// 1. Import the auth provider:
///    ```dart
///    import 'package:provider/provider.dart';
///    import '../providers/auth_provider.dart';
///    ```
/// 
/// 2. Update your login method:
///    ```dart
///    Future<void> _handleLogin() async {
///      final authProvider = Provider.of<AuthProvider>(context, listen: false);
///      
///      // Enable API mode
///      authProvider.setAuthMode(useApi: true);
///      
///      final success = await authProvider.login(
///        _emailController.text,
///        _passwordController.text,
///      );
///      
///      if (success) {
///        // Login successful
///        Navigator.pushReplacementNamed(context, '/main');
///      } else {
///        // Show error
///        setState(() {
///          _errorMessage = authProvider.errorMessage;
///        });
///      }
///    }
///    ```
/// 
/// 3. Add a toggle for API mode in your settings:
///    ```dart
///    Consumer<AuthProvider>(
///      builder: (context, authProvider, _) {
///        return SwitchListTile(
///          title: Text('Use Laravel Backend'),
///          subtitle: Text(authProvider.useApi 
///            ? 'Connected to https://web-production-6d61b.up.railway.app'
///            : 'Using local database'),
///          value: authProvider.useApi,
///          onChanged: (value) {
///            authProvider.setAuthMode(useApi: value);
///          },
///        );
///      },
///    )
///    ```

/// Example 6: Testing the API Integration
/// 
/// To test your Laravel API:
/// 
/// 1. Run this in your main() function or a test screen:
///    ```dart
///    await DirectApiExample.exampleDirectLogin();
///    ```
/// 
/// 2. Check the console output for success/failure messages
/// 
/// 3. Expected Laravel endpoints on your Railway server:
///    - POST /api/login
///    - POST /api/register
///    - GET /api/user (requires auth)
///    - GET /api/users (requires auth)
///    - POST /api/logout (requires auth)
///    - GET /api/health (optional health check)
/// 
/// 4. Expected request/response format:
///    
///    Login Request:
///    ```json
///    {
///      "email": "user@example.com",
///      "password": "password123"
///    }
///    ```
///    
///    Login Response:
///    ```json
///    {
///      "token": "1|abc123...",
///      "user": {
///        "id": 1,
///        "name": "John Doe",
///        "email": "user@example.com",
///        "created_at": "2025-01-01T00:00:00Z",
///        "updated_at": "2025-01-01T00:00:00Z"
///      }
///    }
///    ```