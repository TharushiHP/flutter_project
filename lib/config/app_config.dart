class AppConfig {
  static const bool isDevelopment = true; // Set to false for production
  static const bool enableDatabaseViewer = isDevelopment;
  static const bool enableDebugTools = isDevelopment;
  static const bool enableConsoleLogging = isDevelopment;
  
  // Only show database tools in development
  static bool get shouldShowDatabaseViewer => enableDatabaseViewer;
}