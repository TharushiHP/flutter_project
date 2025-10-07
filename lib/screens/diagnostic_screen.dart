import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/cart_provider.dart';
import '../database/database_helper.dart';

class DiagnosticScreen extends StatelessWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Diagnostics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<DataProvider, CartProvider>(
        builder: (context, dataProvider, cartProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data Provider Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Provider Status',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'API Mode: ${dataProvider.useApiForData ? "Enabled" : "Disabled"}',
                        ),
                        Text('Data Source: ${dataProvider.currentDataSource}'),
                        Text(
                          'Products Loaded: ${dataProvider.products.length}',
                        ),
                        Text(
                          'Categories Loaded: ${dataProvider.categories.length}',
                        ),
                        Text('Is Loading: ${dataProvider.isLoading}'),
                        Text('Error: ${dataProvider.error ?? "None"}'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await dataProvider.forceRefresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Data refreshed!')),
                            );
                          },
                          child: const Text('Force Refresh Data'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final dbHelper = DatabaseHelper();
                              await dbHelper.cleanupInvalidProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Database cleaned! Invalid products removed.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Clean Database',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cart Provider Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cart Provider Status',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Cart Items: ${cartProvider.itemCount}'),
                        Text(
                          'Subtotal: LKR ${cartProvider.subtotal.toStringAsFixed(2)}',
                        ),
                        Text(
                          'Total: LKR ${cartProvider.totalAmount.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        Text('Cart Items Detail:'),
                        ...cartProvider.items.map(
                          (item) => Text(
                            '  • ${item.productName} x${item.quantity} - LKR ${item.price}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Categories Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories Detail',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        ...dataProvider.categories.map((category) {
                          final productCount =
                              dataProvider
                                  .getProductsByCategory(category.name)
                                  .length;
                          return Text(
                            '${category.name}: $productCount products',
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // First 5 Products Info + Duplicate Check
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sample Products (First 5) + Duplicate Check',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        ...dataProvider.products
                            .take(5)
                            .map(
                              (product) => Text(
                                '${product.name} (${product.category}) - ${product.imageUrl}',
                              ),
                            ),
                        const SizedBox(height: 8),
                        Text(
                          'Duplicate Check:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Builder(
                          builder: (context) {
                            final productNames =
                                dataProvider.products
                                    .map((p) => p.name)
                                    .toList();
                            final uniqueNames = productNames.toSet();
                            final duplicates =
                                productNames.length - uniqueNames.length;
                            return Text(
                              'Total products: ${productNames.length}, Unique: ${uniqueNames.length}, Duplicates: $duplicates',
                              style: TextStyle(
                                color:
                                    duplicates > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
