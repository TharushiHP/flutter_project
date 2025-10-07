import 'cart_item.dart';
import 'product.dart';

class Cart {
  static final List<CartItem> _items = [];

  static List<CartItem> get items => _items;

  static void addProduct(Product product) {
    final existingItem = _items.firstWhere(
      (item) => item.product.name == product.name,
      orElse: () => CartItem(product: product, quantity: 0),
    );

    if (existingItem.quantity == 0) {
      _items.add(CartItem(product: product));
    } else {
      existingItem.quantity++;
    }
  }

  static double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  static void clear() => _items.clear();
}
