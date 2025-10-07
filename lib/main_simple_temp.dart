import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/checkout_form_screen.dart';
import 'screens/main_navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/data_provider.dart';
import 'providers/device_capabilities_provider.dart';

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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Simplified startup - just go to main navigation
          return MaterialApp(
            title: 'Grocery Store',
            theme: ThemeData(
              primarySwatch: Colors.green,
              fontFamily: 'Roboto',
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                bodyLarge: TextStyle(fontSize: 16),
                bodyMedium: TextStyle(fontSize: 14),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                color: Colors.white,
                shadowColor: Colors.black12,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
              fontFamily: 'Roboto',
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                bodyLarge: TextStyle(fontSize: 16),
                bodyMedium: TextStyle(fontSize: 14),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                color: Colors.grey[800],
                shadowColor: Colors.black26,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: const MainNavigation(), // Always start with main navigation for now
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainNavigation(),
              '/checkout': (context) => const CheckoutFormScreen(),
            },
          );
        },
      ),
    );
  }
}
