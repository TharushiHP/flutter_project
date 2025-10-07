import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

class DataProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isOnline = true;
  String? _error;
  bool _dataLoaded = false;
  bool _useApiForData = false; // Disable API mode to use only local storage
  String _currentDataSource = 'none'; // Track current data source

  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;
  bool get useApiForData => _useApiForData;
  String get currentDataSource => _currentDataSource;

  DataProvider() {
    _initializeConnectivity();
    // Force reload data to ensure fresh state
    debugPrint('🔄 DataProvider: Initializing with local storage only mode');
    _dataLoaded = false; // Force fresh load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  /// Force refresh data (useful for testing and debugging)
  Future<void> forceRefresh() async {
    debugPrint('🔄 DataProvider: Force refreshing data...');
    _dataLoaded = false;
    _currentDataSource = 'none';
    _products.clear();
    _categories.clear();

    // Clean up invalid products from database
    try {
      await _dbHelper.cleanupInvalidProducts();
      await _dbHelper.clearProducts(); // Clear all to ensure fresh start
      debugPrint('🔄 DataProvider: Cleaned up database');
    } catch (e) {
      debugPrint('⚠️ DataProvider: Could not clean database: $e');
    }

    notifyListeners();
    await loadData();
  }

  void _initializeConnectivity() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      bool wasOnline = _isOnline;
      _isOnline =
          results.isNotEmpty &&
          !results.every((result) => result == ConnectivityResult.none);

      // Only reload if we just came online and don't have API data yet
      if (_isOnline && !wasOnline && _useApiForData && _products.isEmpty) {
        debugPrint('DataProvider: Connection restored, loading API data');
        loadData();
      }
      notifyListeners();
    });
  }

  Future<void> loadData() async {
    // Skip loading if data is already cached and source hasn't changed
    if (_dataLoaded && _products.isNotEmpty && _categories.isNotEmpty) {
      debugPrint('DataProvider: Data already loaded, skipping');
      // Notify listeners immediately to trigger UI update
      notifyListeners();
      return;
    }

    // Prevent multiple simultaneous loading operations
    if (_isLoading) {
      debugPrint('DataProvider: Already loading, skipping duplicate request');
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      // Load from local data first for immediate display, then try API
      if (!_dataLoaded) {
        debugPrint(
          'DataProvider: Loading local data first for immediate display',
        );
        await _loadDataFromLocal();
        _setLoading(false);
        _dataLoaded = true;

        // If API is enabled and online, try to update with API data later
        if (_useApiForData && _isOnline) {
          debugPrint(
            'DataProvider: API mode enabled, will use hybrid approach',
          );
        }
        return;
      }

      // Try API first if enabled and online
      if (_useApiForData && _isOnline) {
        debugPrint('DataProvider: Attempting to load data from Laravel API');
        try {
          await _loadDataFromApi();
          debugPrint(
            'DataProvider: ✅ API loading successful - using API data exclusively',
          );
          _dataLoaded = true;
          _setLoading(false);
          return; // Success! Exit early, don't load local data
        } catch (apiError) {
          debugPrint('DataProvider: ❌ API loading failed: $apiError');
          debugPrint('DataProvider: 🔄 Falling back to local data');
          _error = null; // Clear API error since we're falling back
        }
      }

      // Fallback to local data (either API disabled/offline or API failed)
      debugPrint('DataProvider: Loading data from local sources');
      await _loadDataFromLocal();
      debugPrint('DataProvider: ✅ Local loading successful');
      _dataLoaded = true;
    } catch (e) {
      _error = 'Failed to load data from all sources: $e';
      debugPrint('DataProvider: ❌ Both API and local loading failed: $e');
    }

    _setLoading(false);
  }

  /// Load data from Laravel API (hybrid mode)
  Future<void> _loadDataFromApi() async {
    try {
      debugPrint('🌐 [WEB/MOBILE] DataProvider: Starting API data loading...');

      // Fetch products and categories from API
      final apiProducts = await apiService.fetchProducts();
      final apiCategories = await apiService.fetchCategories();

      debugPrint('📊 DataProvider: API Products count: ${apiProducts.length}');
      debugPrint(
        '📊 DataProvider: API Categories count: ${apiCategories.length}',
      );
      debugPrint('🎯 [DATA SOURCE]: Using Laravel API data exclusively');

      // Convert API data to local models
      _products = apiProducts.map((data) => Product.fromMap(data)).toList();
      _categories =
          apiCategories.map((data) => Category.fromMap(data)).toList();

      // Set data source
      _currentDataSource = 'api';
      debugPrint(
        '✅ DataProvider: Current data source set to: $_currentDataSource',
      );

      // Cache API data locally for offline use (but don't fail if caching fails)
      try {
        await _cacheApiDataLocally(_products, _categories);
      } catch (cacheError) {
        debugPrint(
          'DataProvider: Failed to cache API data: $cacheError (continuing anyway)',
        );
      }

      debugPrint(
        'DataProvider: Successfully loaded ${_products.length} products and ${_categories.length} categories from API',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('DataProvider: API loading failed: $e');
      rethrow; // Let caller handle fallback
    }
  }

  /// Load data from local sources (database + assets)
  Future<void> _loadDataFromLocal() async {
    try {
      debugPrint(
        '💾 [WEB/MOBILE] DataProvider: Starting local data loading...',
      );

      // Load categories first
      await loadCategories();
      // Then load products
      await loadProducts();

      // Set data source
      _currentDataSource = 'local';
      debugPrint('📊 DataProvider: Local Products count: ${_products.length}');
      debugPrint(
        '📊 DataProvider: Local Categories count: ${_categories.length}',
      );
      debugPrint('🎯 [DATA SOURCE]: Using Local Assets/Database data');
      debugPrint(
        '✅ DataProvider: Current data source set to: $_currentDataSource',
      );

      debugPrint(
        'DataProvider: Successfully loaded ${_products.length} products and ${_categories.length} categories from local sources',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('DataProvider: Local loading failed: $e');
      rethrow;
    }
  }

  /// Cache API data locally for offline fallback
  Future<void> _cacheApiDataLocally(
    List<Product> products,
    List<Category> categories,
  ) async {
    try {
      // Cache products (replace existing)
      for (final product in products) {
        await _dbHelper.insertProduct(product);
      }

      // Cache categories (replace existing)
      for (final category in categories) {
        await _dbHelper.insertCategory(category);
      }

      debugPrint(
        'DataProvider: Cached ${products.length} products and ${categories.length} categories locally',
      );
    } catch (e) {
      debugPrint('DataProvider: Failed to cache API data locally: $e');
      // Don't throw - caching failure shouldn't break the app
    }
  }

  Future<void> loadProducts() async {
    try {
      // Clear existing products to prevent duplicates
      _products.clear();

      if (kIsWeb) {
        // For web platform, load from assets directly
        debugPrint('🌐 [WEB] Loading products from assets...');
        _products = await _loadProductsFromAssets();
        debugPrint('🌐 [WEB] Loaded ${_products.length} products from assets');
      } else {
        // For mobile, clean up database first, then use assets
        debugPrint('📱 [MOBILE] Cleaning up invalid products from database...');
        await _dbHelper.cleanupInvalidProducts();

        debugPrint('📱 [MOBILE] Loading products from assets only...');
        _products = await _loadProductsFromAssets();
        debugPrint(
          '📱 [MOBILE] Loaded ${_products.length} products from assets',
        );

        // Refresh database with clean data
        await _dbHelper.clearProducts();
        for (final product in _products) {
          // Only insert products with valid image URLs
          if (product.imageUrl.isNotEmpty &&
              product.imageUrl.startsWith('assets/images/')) {
            await _dbHelper.insertProduct(product);
          }
        }
        debugPrint(
          '📱 [MOBILE] Refreshed database with ${_products.length} valid products',
        );
      }

      // Remove duplicates by ID just in case
      final Map<String, Product> uniqueProducts = {};
      for (final product in _products) {
        uniqueProducts[product.id] = product;
      }
      _products = uniqueProducts.values.toList();

      debugPrint(
        '✅ Final product count after deduplication: ${_products.length}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading products: $e');
      // Fallback to direct asset loading
      try {
        debugPrint('🚨 [FALLBACK] Loading products from assets...');
        _products = await _loadProductsFromAssets();
        debugPrint(
          '🚨 [FALLBACK] Loaded ${_products.length} products from assets',
        );
        notifyListeners();
      } catch (assetError) {
        debugPrint('Error loading products from assets: $assetError');
      }
    }
  }

  Future<void> loadCategories() async {
    try {
      if (kIsWeb) {
        // For web platform, load from assets directly
        debugPrint('🌐 [WEB] Loading categories from assets...');
        _categories = await _loadCategoriesFromAssets();
        debugPrint(
          '🌐 [WEB] Loaded ${_categories.length} categories from assets',
        );
      } else {
        // Try database first
        debugPrint('📱 [MOBILE] Loading categories from database...');
        _categories = await _dbHelper.getAllCategories();

        // If database is empty, load from assets and populate database
        if (_categories.isEmpty) {
          debugPrint('📱 [MOBILE] Database empty, loading from assets...');
          _categories = await _loadCategoriesFromAssets();
          // Save to database for future use
          for (final category in _categories) {
            await _dbHelper.insertCategory(category);
          }
          debugPrint(
            '📱 [MOBILE] Saved ${_categories.length} categories to database',
          );
        } else {
          debugPrint(
            '📱 [MOBILE] Loaded ${_categories.length} categories from database',
          );
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Fallback to direct asset loading
      try {
        debugPrint('🚨 [FALLBACK] Loading categories from assets...');
        _categories = await _loadCategoriesFromAssets();
        debugPrint(
          '🚨 [FALLBACK] Loaded ${_categories.length} categories from assets',
        );
        notifyListeners();
      } catch (assetError) {
        debugPrint('Error loading categories from assets: $assetError');
      }
    }
  }

  List<Product> getProductsByCategory(String categoryName) {
    final filteredProducts =
        _products
            .where(
              (product) =>
                  product.category.toLowerCase() == categoryName.toLowerCase(),
            )
            .toList();

    debugPrint(
      '📱 getProductsByCategory: $categoryName -> ${filteredProducts.length} products',
    );
    debugPrint('📱 Total products available: ${_products.length}');
    debugPrint('📱 Data source: $_currentDataSource');

    return filteredProducts;
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id.toString() == id);
    } catch (e) {
      return null;
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id.toString() == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
          product.description.toLowerCase().contains(lowercaseQuery) ||
          product.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  List<Product> getFeaturedProducts({int limit = 10}) {
    return _products
        .where((product) => product.rating >= 4.0)
        .take(limit)
        .toList();
  }

  List<Category> getFeaturedCategories() {
    return _categories.where((category) => category.featured).toList();
  }

  /// Get a human-readable description of the current data source
  String getDataSourceInfo() {
    switch (_currentDataSource) {
      case 'api':
        return '🌐 Laravel API (${_products.length} products, ${_categories.length} categories)';
      case 'local':
        if (kIsWeb) {
          return '💾 Web Assets (${_products.length} products, ${_categories.length} categories)';
        } else {
          return '📱 Local Database (${_products.length} products, ${_categories.length} categories)';
        }
      default:
        return '❓ Unknown source (${_products.length} products, ${_categories.length} categories)';
    }
  }

  Future<void> refreshData() async {
    await loadData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to load products from assets
  Future<List<Product>> _loadProductsFromAssets() async {
    try {
      final String productsJson = await rootBundle.loadString(
        'assets/data/products.json',
      );
      final List<dynamic> productsData = jsonDecode(productsJson);
      return productsData.map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error loading products from assets: $e');
      return [];
    }
  }

  // Helper method to load categories from assets
  Future<List<Category>> _loadCategoriesFromAssets() async {
    try {
      final String categoriesJson = await rootBundle.loadString(
        'assets/data/categories.json',
      );
      final List<dynamic> categoriesData = jsonDecode(categoriesJson);
      return categoriesData.map((item) => Category.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error loading categories from assets: $e');
      return [];
    }
  }
}
