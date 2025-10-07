import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    // Skip database initialization on web platform
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on web platform. Use JSON assets instead.',
      );
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on web platform. Use JSON assets instead.',
      );
    }

    String path = join(await getDatabasesPath(), 'grocery_store.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        image_url TEXT,
        rating REAL DEFAULT 0.0,
        in_stock INTEGER DEFAULT 1,
        is_available INTEGER DEFAULT 1,
        nutrition_info TEXT,
        origin TEXT,
        expiry_date TEXT,
        quantity_in_stock INTEGER DEFAULT 0,
        review_count INTEGER DEFAULT 0,
        unit TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        image_url TEXT,
        color TEXT,
        featured INTEGER DEFAULT 0
      )
    ''');

    // Cart items table
    await db.execute('''
      CREATE TABLE cart_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        image_url TEXT,
        added_at TEXT NOT NULL
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        address TEXT,
        created_at TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        order_date TEXT NOT NULL,
        delivery_address TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Order items table
    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');

    // User preferences table for theme and settings
    await db.execute('''
      CREATE TABLE user_preferences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        preference_key TEXT NOT NULL,
        preference_value TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);

    // Insert default test user
    await _insertDefaultUser(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Drop and recreate tables for schema changes
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS categories');

      // Recreate with new schema
      await db.execute('''
        CREATE TABLE products(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL,
          category TEXT NOT NULL,
          image_url TEXT,
          rating REAL DEFAULT 0.0,
          in_stock INTEGER DEFAULT 1,
          is_available INTEGER DEFAULT 1,
          nutrition_info TEXT,
          origin TEXT,
          expiry_date TEXT,
          quantity_in_stock INTEGER DEFAULT 0,
          review_count INTEGER DEFAULT 0,
          unit TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE categories(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          image_url TEXT,
          color TEXT,
          featured INTEGER DEFAULT 0
        )
      ''');

      // Re-insert default categories
      await _insertDefaultCategories(db);
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      {
        'name': 'Vegetables',
        'description': 'Fresh vegetables and greens',
        'image_url': 'assets/images/vegetables.webp',
        'featured': 1,
      },
      {
        'name': 'Fruits',
        'description': 'Fresh seasonal fruits',
        'image_url': 'assets/images/fruit.jpeg',
        'featured': 1,
      },
      {
        'name': 'Dairy',
        'description': 'Milk, cheese, and dairy products',
        'image_url': 'assets/images/dairy.jpeg',
        'featured': 1,
      },
      {
        'name': 'Grains',
        'description': 'Rice, wheat, and cereals',
        'image_url': 'assets/images/grains.jpeg',
        'featured': 0,
      },
      {
        'name': 'Meat',
        'description': 'Fresh meat and poultry',
        'image_url': 'assets/images/meat.webp',
        'featured': 0,
      },
      {
        'name': 'Bakery',
        'description': 'Bread, cakes, and baked goods',
        'image_url': 'assets/images/bakery.jpg',
        'featured': 1,
      },
    ];

    for (var category in categories) {
      await db.insert('categories', category);
    }
  }

  Future<void> _insertDefaultUser(Database db) async {
    // Create a default test user for easy login
    final testUser = {
      'name': 'Test User',
      'email': 'test@groceries.com',
      'phone': '+1234567890',
      'address': '123 Test Street',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    };

    try {
      await db.insert('users', testUser);
      debugPrint('Default test user created: test@groceries.com');
    } catch (e) {
      debugPrint('Test user already exists or error: $e');
    }
  }

  // CRUD Operations for Products
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Categories
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<List<Category>> getFeaturedCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'featured = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // CRUD Operations for Cart Items
  Future<int> insertCartItem(CartItem item) async {
    final db = await database;

    // Check if item already exists in cart
    final existing = await db.query(
      'cart_items',
      where: 'product_id = ?',
      whereArgs: [item.productId],
    );

    if (existing.isNotEmpty) {
      // Update quantity
      final existingItem = CartItem.fromMap(existing.first);
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
      return await updateCartItem(updatedItem);
    } else {
      // Insert new item
      return await db.insert('cart_items', item.toMap());
    }
  }

  Future<List<CartItem>> getAllCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cart_items');
    return List.generate(maps.length, (i) => CartItem.fromMap(maps[i]));
  }

  Future<int> updateCartItem(CartItem item) async {
    final db = await database;
    return await db.update(
      'cart_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteCartItem(int id) async {
    final db = await database;
    return await db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearCart() async {
    final db = await database;
    return await db.delete('cart_items');
  }

  // CRUD Operations for Users
  Future<int> insertUser(User user) async {
    try {
      debugPrint('DatabaseHelper: Inserting user: ${user.email}');
      final db = await database;
      final result = await db.insert('users', user.toMap());
      debugPrint('DatabaseHelper: User inserted successfully with ID: $result');
      return result;
    } catch (e) {
      debugPrint('DatabaseHelper: Error inserting user: $e');
      debugPrint('DatabaseHelper: User data: ${user.toMap()}');
      rethrow;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      debugPrint('DatabaseHelper: Looking for user with email: $email');
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      debugPrint(
        'DatabaseHelper: Found ${maps.length} users with email: $email',
      );
      if (maps.isNotEmpty) {
        final user = User.fromMap(maps.first);
        debugPrint('DatabaseHelper: Returning user: ${user.name}');
        return user;
      }
      debugPrint('DatabaseHelper: No user found with email: $email');
      return null;
    } catch (e) {
      debugPrint('DatabaseHelper: Error getting user by email: $e');
      return null;
    }
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // CRUD Operations for Orders
  Future<int> insertOrder(Order order) async {
    final db = await database;

    // Insert order
    final orderId = await db.insert('orders', order.toMap());

    // Insert order items
    for (var item in order.items) {
      await db.insert('order_items', {
        'order_id': orderId,
        'product_id': item.productId,
        'product_name': item.productName,
        'price': item.price,
        'quantity': item.quantity,
      });
    }

    return orderId;
  }

  Future<List<Order>> getOrdersByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'order_date DESC',
    );

    List<Order> orders = [];
    for (var orderMap in orderMaps) {
      // Get order items
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderMap['id']],
      );

      final items =
          itemMaps
              .map(
                (itemMap) => OrderItem(
                  orderId: (orderMap['id'] as int?) ?? 0,
                  productId: (itemMap['product_id'] as int?)?.toString() ?? '0',
                  productName: (itemMap['product_name'] as String?) ?? '',
                  price: (itemMap['price'] as double?) ?? 0.0,
                  quantity: (itemMap['quantity'] as int?) ?? 0,
                ),
              )
              .toList();

      orders.add(
        Order(
          id: (orderMap['id'] as int?) ?? 0,
          userId: (orderMap['user_id'] as int?) ?? 0,
          totalAmount: (orderMap['total_amount'] as double?) ?? 0.0,
          status: (orderMap['status'] as String?) ?? '',
          orderDate: DateTime.parse(orderMap['order_date'] as String),
          deliveryAddress: orderMap['delivery_address'] as String?,
          items: items,
        ),
      );
    }

    return orders;
  }

  // User Preferences
  Future<int> setUserPreference(int? userId, String key, String value) async {
    final db = await database;

    // Check if preference exists
    final existing = await db.query(
      'user_preferences',
      where: 'user_id = ? AND preference_key = ?',
      whereArgs: [userId, key],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'user_preferences',
        {'preference_value': value},
        where: 'user_id = ? AND preference_key = ?',
        whereArgs: [userId, key],
      );
    } else {
      return await db.insert('user_preferences', {
        'user_id': userId,
        'preference_key': key,
        'preference_value': value,
      });
    }
  }

  Future<String?> getUserPreference(int? userId, String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      where: 'user_id = ? AND preference_key = ?',
      whereArgs: [userId, key],
    );

    if (maps.isNotEmpty) {
      return maps.first['preference_value'];
    }
    return null;
  }

  // Search functionality
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Database maintenance
  Future<void> clearProducts() async {
    final db = await database;
    await db.delete('products');
    debugPrint('🗑️ DatabaseHelper: Cleared all products from database');
  }

  Future<void> removeProductsWithoutImages() async {
    final db = await database;
    // Remove products with null, empty, or invalid image URLs
    final deletedCount = await db.delete(
      'products',
      where:
          'imageUrl IS NULL OR imageUrl = ? OR imageUrl = ? OR imageUrl NOT LIKE ?',
      whereArgs: ['', 'null', 'assets/images/%'],
    );
    debugPrint(
      '🗑️ DatabaseHelper: Removed $deletedCount products without proper image URLs',
    );
  }

  Future<void> cleanupInvalidProducts() async {
    final db = await database;

    // Get all products to check their data
    final List<Map<String, dynamic>> products = await db.query('products');
    debugPrint(
      '📊 DatabaseHelper: Found ${products.length} products in database',
    );

    int removedCount = 0;
    for (final productMap in products) {
      final imageUrl = productMap['imageUrl'] as String?;
      final name = productMap['name'] as String?;

      // Remove products with problematic data
      if (imageUrl == null ||
          imageUrl.isEmpty ||
          imageUrl == 'null' ||
          name == null ||
          name.isEmpty ||
          !imageUrl.startsWith('assets/images/')) {
        await db.delete(
          'products',
          where: 'id = ?',
          whereArgs: [productMap['id']],
        );
        removedCount++;
        debugPrint(
          '🗑️ Removed invalid product: ${name ?? "Unknown"} with image: ${imageUrl ?? "null"}',
        );
      }
    }

    debugPrint(
      '✅ DatabaseHelper: Cleanup complete. Removed $removedCount invalid products',
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('cart_items');
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('products');
    await db.delete('user_preferences');
    await db.delete('users');
    // Don't clear categories as they're default data
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
