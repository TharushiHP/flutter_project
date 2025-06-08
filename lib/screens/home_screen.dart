import 'package:flutter/material.dart';
import '../../models/category.dart';
import 'product_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      Category('Vegetables', 'assets/images/vegetables.webp'),
      Category('Fruits', 'assets/images/fruit.jpeg'),
      Category('Meat', 'assets/images/meat.webp'),
      Category('Dairy', 'assets/images/dairy.jpeg'),
      Category('Grains', 'assets/images/grains.jpeg'),
      Category('Bakery', 'assets/images/bakery.jpg'),
    ];

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            // Portrait layout
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  color: Colors.green,
                  child: const Text(
                    "Shop by Category",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(12.0),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children:
                        categories.map((category) {
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ProductListScreen(
                                          category: category.title,
                                        ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.asset(
                                        category.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      category.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            );
          } else {
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: Image.asset(category.imageUrl, width: 60),
                  title: Text(category.title),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ProductListScreen(category: category.title),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
