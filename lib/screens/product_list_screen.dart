import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

final Map<String, List<Product>> categoryProducts = {
  'Vegetables': [
    Product(
      name: 'Tomato',
      imageUrl: 'assets/images/tomatoes.jpg',
      price: 200,
      description: 'Freshly picked organic tomatoes',
    ),
    Product(
      name: 'Beans',
      imageUrl: 'assets/images/beans.jpg',
      price: 150,
      description: 'Fresh green beans from local farmers',
    ),
  ],
  'Fruits': [
    Product(
      name: 'Mango',
      imageUrl: 'assets/images/mangoes.jpg',
      price: 120,
      description: 'Juicy and sweet tropical mangoes',
    ),
    Product(
      name: 'Banana',
      imageUrl: 'assets/images/bananas.jpg',
      price: 150,
      description: 'Fresh bananas from local farmers',
    ),
  ],
  'Dairy': [
    Product(
      name: 'Butter',
      imageUrl: 'assets/images/butter.jpg',
      price: 400,
      description: 'Salted butter ideal for cooking, baking, and spreading.',
    ),
    Product(
      name: 'Curd',
      imageUrl: 'assets/images/curd.jpg',
      price: 350,
      description: 'Homemade-style thick curd',
    ),
  ],
  'Meat': [
    Product(
      name: 'Beef',
      imageUrl: 'assets/images/beef.jpg',
      price: 900,
      description: 'Fresh beef cuts',
    ),
    Product(
      name: 'Pork',
      imageUrl: 'assets/images/pork.jpg',
      price: 450,
      description: 'Tender pork slices',
    ),
  ],
  'Grains': [
    Product(
      name: 'Dhal',
      imageUrl: 'assets/images/dhal.jpg',
      price: 400,
      description: 'Protein-rich red lentils',
    ),
    Product(
      name: 'Green Gram',
      imageUrl: 'assets/images/green_gram.jpg',
      price: 350,
      description: 'Nutritious green gram ',
    ),
  ],
  'Bakery': [
    Product(
      name: 'Bread',
      imageUrl: 'assets/images/bread.jpg',
      price: 200,
      description: 'Freshly baked soft white bread',
    ),
  ],
};

class ProductListScreen extends StatelessWidget {
  final String category;

  const ProductListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final products = categoryProducts[category] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading: Hero(
                    tag: product.name,
                    child: Image.asset(product.imageUrl, width: 50, height: 50),
                  ),
                  title: Text(product.name),
                  subtitle: Text('Rs.${product.price.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder:
                            (_, animation, __) => SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: ProductDetailScreen(product: product),
                            ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder:
                            (_, animation, __) => SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: ProductDetailScreen(product: product),
                            ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: product.name,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                            child: Image.asset(
                              product.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Rs.${product.price.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
