import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import 'checkout_form_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartItems = Cart.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body:
          cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return ListTile(
                          title: Text(item.product.name),
                          subtitle: Text(
                            'Qty: ${item.quantity} x Rs.${item.product.price.toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            'Rs.${(item.product.price * item.quantity).toStringAsFixed(2)}',
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Total: Rs.${Cart.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration: const Duration(
                                  milliseconds: 500,
                                ),
                                pageBuilder:
                                    (_, animation, __) => FadeTransition(
                                      opacity: animation,
                                      child: const CheckoutFormScreen(),
                                    ),
                              ),
                            );
                          },
                          child: const Text('Proceed to Checkout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
