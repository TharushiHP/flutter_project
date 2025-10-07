import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/checkout_form_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/location_map_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/data_provider.dart';
import 'providers/device_capabilities_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GroceryApp());
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => DeviceCapabilitiesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          // Initialize auth and theme on first build if needed
          if (authProvider.status == AuthStatus.uninitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authProvider.initializeAuth();
            });
          }

          if (!themeProvider.isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeProvider.initializeTheme();
            });
          }

          return MaterialApp(
            title: 'Grocery Store',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: _buildHomeScreen(authProvider),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainNavigation(),
              '/cart': (context) => const CartScreen(),
              '/checkout': (context) => const CheckoutFormScreen(),
              '/location': (context) => const LocationMapScreen(),
              '/camera': (context) => const CameraPlaceholderScreen(),
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(AuthProvider authProvider) {
    switch (authProvider.status) {
      case AuthStatus.uninitialized:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const MainNavigation();
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
        return const LoginScreen();
    }
  }

  // Build light theme with consistent color scheme
  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      fontFamily: 'Roboto',
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black12,
        margin: EdgeInsets.all(8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Build dark theme with consistent color scheme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.grey[800],
        shadowColor: Colors.black26,
        margin: const EdgeInsets.all(8.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Temporary camera placeholder screen
class CameraPlaceholderScreen extends StatelessWidget {
  const CameraPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Camera Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<DeviceCapabilitiesProvider>(
        builder: (context, deviceProvider, child) {
          if (!deviceProvider.cameraPermissionGranted) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Camera Permission Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please enable camera access to scan products',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (!deviceProvider.isCameraInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            children: [
              // Camera preview
              Positioned.fill(
                child: CameraPreview(deviceProvider.cameraController!),
              ),

              // Scanner overlay
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.center_focus_strong,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                ),
              ),

              // Instructions overlay
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Position product barcode in the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Take a photo to add to your shopping list',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () => _takePicture(context, deviceProvider),
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _takePicture(
    BuildContext context,
    DeviceCapabilitiesProvider deviceProvider,
  ) async {
    try {
      final image = await deviceProvider.takePicture();
      if (image != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
