import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  final double _deliveryFee = 250.0; // Delivery fee in LKR
  final double _freeDeliveryThreshold = 2000.0; // Free delivery over 2000 LKR
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<CartItem> get items => [..._items];

  double get deliveryFee => _deliveryFee;

  double get freeDeliveryThreshold => _freeDeliveryThreshold;

  bool get isFreeDelivery => subtotal >= _freeDeliveryThreshold;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    double total = _items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    // Add delivery fee only if order doesn't qualify for free delivery
    return total + (total > 0 && !isFreeDelivery ? _deliveryFee : 0);
  }

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      _items = await _dbHelper.getAllCartItems();
      notifyListeners();
      debugPrint('📦 Loaded ${_items.length} items from SQLite cart database');
    } catch (e) {
      debugPrint('❌ Failed to load cart from database: $e');
      _items = [];
    }
  }

  Future<void> _saveCart() async {
    try {
      // Clear existing cart items and re-insert all current items
      await _dbHelper.clearCart();
      for (final item in _items) {
        await _dbHelper.insertCartItem(item);
      }
      debugPrint('💾 Saved ${_items.length} items to SQLite cart database');
    } catch (e) {
      debugPrint('❌ Failed to save cart to database: $e');
    }
  }

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(
        CartItem(
          productId: product.id,
          productName: product.name,
          price: product.price, // Price is already in LKR
          quantity: quantity,
          imageUrl: product.imageUrl,
        ),
      );
    }

    _saveCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse:
          () => CartItem(
            productId: '0',
            productName: '',
            price: 0,
            quantity: 0,
            imageUrl: '',
          ),
    );
    return item.quantity;
  }

  // New method to get cart item details
  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }
}
