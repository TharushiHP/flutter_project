import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getQuantity(widget.product.id.toString());

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, cartProvider, quantity),
              _buildProductInfo(),
              _buildTabSection(),
              _buildTabContent(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, cartProvider, quantity),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    CartProvider cartProvider,
    int quantity,
  ) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // Add to favorites
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.product.name} added to favorites'),
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Hero(
            tag: 'product_${widget.product.id}',
            child: Image.asset(
              widget.product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name and category
            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.product.category,
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price and rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs ${widget.product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    if (widget.product.price > 500)
                      Text(
                        'Free delivery',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          widget.product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '(${(widget.product.rating * 47).round()} reviews)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    widget.product.inStock ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      widget.product.inStock
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.product.inStock ? Icons.check_circle : Icons.warning,
                    color:
                        widget.product.inStock
                            ? Colors.green[600]
                            : Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.product.inStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      color:
                          widget.product.inStock
                              ? Colors.green[700]
                              : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Origin and expiry
            if (widget.product.origin != null ||
                widget.product.expiryDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (widget.product.origin != null) ...[
                      Icon(Icons.place, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Origin: ${widget.product.origin}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    if (widget.product.origin != null &&
                        widget.product.expiryDate != null)
                      const SizedBox(width: 16),
                    if (widget.product.expiryDate != null) ...[
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Best before: ${_formatDate(widget.product.expiryDate!)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green[700],
          tabs: const [
            Tab(text: 'Description'),
            Tab(text: 'Nutrition'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDescriptionTab(),
            _buildNutritionTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (widget.product.category.toLowerCase().contains('fruit') ||
              widget.product.category.toLowerCase().contains('vegetable'))
            _buildHealthBenefits(),
        ],
      ),
    );
  }

  Widget _buildHealthBenefits() {
    final benefits = _getHealthBenefits(widget.product.name.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Benefits:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...benefits.map(
          (benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(benefit)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutritional Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.product.nutritionInfo != null)
            Text(
              widget.product.nutritionInfo!,
              style: const TextStyle(fontSize: 16),
            )
          else
            _buildDefaultNutrition(),
        ],
      ),
    );
  }

  Widget _buildDefaultNutrition() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          NutritionRow(label: 'Calories', value: '52 kcal'),
          NutritionRow(label: 'Carbohydrates', value: '14 g'),
          NutritionRow(label: 'Protein', value: '0.3 g'),
          NutritionRow(label: 'Fat', value: '0.2 g'),
          NutritionRow(label: 'Fiber', value: '2.4 g'),
          NutritionRow(label: 'Vitamin C', value: '53 mg'),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildReviewSummary(),
          const SizedBox(height: 20),
          Expanded(child: _buildReviewsList()),
        ],
      ),
    );
  }

  Widget _buildReviewSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                widget.product.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < widget.product.rating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber[600],
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                5,
                (index) => _buildRatingBar(
                  5 - index,
                  (widget.product.rating - (5 - index - 1)).clamp(0, 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars'),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    final reviews = _generateSampleReviews();

    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green[100],
                      child: Text(
                        review['name'][0],
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < review['rating']
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber[600],
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      review['date'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(review['comment']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    CartProvider cartProvider,
    int quantity,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child:
            quantity > 0
                ? Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed:
                                () => cartProvider.removeItem(
                                  widget.product.id.toString(),
                                ),
                            icon: const Icon(Icons.remove, size: 20),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                widget.product.inStock
                                    ? () => cartProvider.addItem(widget.product)
                                    : null,
                            icon: const Icon(Icons.add, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Go to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        widget.product.inStock
                            ? () {
                              cartProvider.addItem(widget.product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${widget.product.name} added to cart',
                                  ),
                                  backgroundColor: Colors.green[600],
                                ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.product.inStock
                              ? Colors.green[600]
                              : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      widget.product.inStock ? 'Add to Cart' : 'Out of Stock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<String> _getHealthBenefits(String productName) {
    if (productName.contains('banana')) {
      return [
        'Rich in potassium for heart health',
        'Good source of vitamin B6',
        'Contains dietary fiber',
        'Natural energy booster',
      ];
    } else if (productName.contains('tomato')) {
      return [
        'High in vitamin C and lycopene',
        'Supports heart health',
        'Low in calories',
        'Contains antioxidants',
      ];
    } else if (productName.contains('mango')) {
      return [
        'Rich in vitamin A and C',
        'Supports immune system',
        'Contains folate',
        'Natural source of beta-carotene',
      ];
    }
    return [
      'Natural source of vitamins',
      'Contains essential nutrients',
      'Part of a balanced diet',
      'Fresh and healthy option',
    ];
  }

  List<Map<String, dynamic>> _generateSampleReviews() {
    return [
      {
        'name': 'Sarah Johnson',
        'rating': 5,
        'date': '2 days ago',
        'comment':
            'Fresh and delicious! Exactly what I expected. Will definitely buy again.',
      },
      {
        'name': 'Mike Chen',
        'rating': 4,
        'date': '1 week ago',
        'comment': 'Good quality product. Fast delivery and well packaged.',
      },
      {
        'name': 'Emily Davis',
        'rating': 5,
        'date': '2 weeks ago',
        'comment': 'Perfect ripeness and great taste. My family loved it!',
      },
    ];
  }
}

class NutritionRow extends StatelessWidget {
  final String label;
  final String value;

  const NutritionRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
