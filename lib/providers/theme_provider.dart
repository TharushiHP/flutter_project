import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage app theme settings including light/dark mode
/// Stores theme preference in SharedPreferences for persistence
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get isInitialized => _isInitialized;

  /// Initialize theme settings from SharedPreferences
  Future<void> initializeTheme() async {
    _prefs = await SharedPreferences.getInstance();

    // Load saved theme preference
    final savedThemeIndex =
        _prefs.getInt('theme_mode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[savedThemeIndex];

    _isInitialized = true;
    notifyListeners();
  }

  /// Set theme mode to light
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Set theme mode to dark
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Set theme mode to system (follows device setting)
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    await _prefs.setInt('theme_mode', _themeMode.index);
  }

  /// Get current brightness based on theme mode and system settings
  Brightness getCurrentBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Check if current theme is dark based on context
  bool isDarkTheme(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }
}
