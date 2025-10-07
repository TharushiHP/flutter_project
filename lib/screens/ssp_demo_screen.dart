import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../widgets/product_card.dart';

class SSPDemoScreen extends StatefulWidget {
  const SSPDemoScreen({super.key});

  @override
  State<SSPDemoScreen> createState() => _SSPDemoScreenState();
}

class _SSPDemoScreenState extends State<SSPDemoScreen> {
  List<Product> _sspProducts = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _sspInfo;

  // Your SSP endpoint
  static const String _sspBaseUrl =
      'https://web-production-6d61b.up.railway.app';

  @override
  void initState() {
    super.initState();
    _fetchSSPProducts();
  }

  Future<void> _fetchSSPProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Test SSP connectivity first
      await _testSSPConnection();

      // Fetch products from SSP with web-specific headers
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // Add web-specific headers if running on web
      if (kIsWeb) {
        headers['Access-Control-Allow-Origin'] = '*';
        headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS';
        headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
      }

      debugPrint('🌐 Attempting to fetch from: $_sspBaseUrl/api/products');
      debugPrint('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');

      final response = await http
          .get(Uri.parse('$_sspBaseUrl/api/products'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug: Print response structure
        debugPrint('SSP Response: ${response.body}');

        List<dynamic> productsData;

        // Handle different response structures
        if (data is Map && data.containsKey('data')) {
          if (data['data'] is Map && data['data'].containsKey('products')) {
            productsData = data['data']['products'];
          } else if (data['data'] is List) {
            productsData = data['data'];
          } else {
            productsData = [];
          }
        } else if (data is List) {
          productsData = data;
        } else {
          productsData = [];
        }

        setState(() {
          _sspProducts =
              productsData.map((item) => _convertSSPToProduct(item)).toList();
          _isLoading = false;
        });

        debugPrint('✅ Loaded ${_sspProducts.length} products from SSP');
        // Debug: Print first few products with image info
        for (int i = 0; i < _sspProducts.length && i < 3; i++) {
          final product = _sspProducts[i];
          debugPrint(
            '🖼️ Product: ${product.name} -> Image: ${product.imageUrl}',
          );
        }
      } else {
        throw Exception(
          'Failed to load products: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Provide more specific error messages
      if (e.toString().contains('TimeoutException')) {
        errorMessage =
            'Connection timeout. The SSP server might be slow or unreachable.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage =
            'SSL/Certificate error. The SSP server might have certificate issues.';
      } else if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
        errorMessage =
            'CORS error. The SSP server might not allow web requests from this domain.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
      debugPrint('❌ SSP Error: $e');
      debugPrint('❌ Platform: ${kIsWeb ? "Web" : "Mobile"}');
    }
  }

  Future<void> _testSSPConnection() async {
    try {
      final headers = {'Accept': 'application/json'};

      if (kIsWeb) {
        headers['Access-Control-Allow-Origin'] = '*';
      }

      debugPrint('🔍 Testing SSP connection...');

      final response = await http
          .get(Uri.parse('$_sspBaseUrl/api/health'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sspInfo = data;
        });
        debugPrint('✅ SSP Health Check: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ SSP Health Check Failed: $e');
    }
  }

  // Convert SSP product data to your Product model
  Product _convertSSPToProduct(Map<String, dynamic> sspData) {
    // Handle image URL mapping
    String imageUrl = _mapSSPImageToLocal(sspData);

    return Product(
      id: sspData['id']?.toString() ?? '',
      name: sspData['name'] ?? 'Unknown Product',
      price: _parsePrice(sspData['price']),
      description: sspData['description'] ?? '',
      category: sspData['category'] ?? 'General',
      imageUrl: imageUrl,
      isAvailable: sspData['stock'] != null ? (sspData['stock'] > 0) : true,
      rating: _parseRating(sspData['rating']),
      reviewCount: sspData['review_count'] ?? 0,
      nutritionInfo: sspData['nutrition_info'],
      origin: sspData['origin'],
      expiryDate:
          sspData['expiry_date'] != null
              ? DateTime.tryParse(sspData['expiry_date'])
              : null,
      quantityInStock: sspData['stock'] ?? 0,
    );
  }

  // Map SSP image filenames to local asset paths
  String _mapSSPImageToLocal(Map<String, dynamic> sspData) {
    // Get image filename from SSP data
    String? sspImage =
        sspData['image'] ?? sspData['image_url'] ?? sspData['picture'];

    if (sspImage != null && sspImage.isNotEmpty) {
      // Check if it's already a full URL
      if (sspImage.startsWith('http')) {
        return sspImage;
      }

      // Map to local assets
      return 'assets/images/$sspImage';
    }

    // Fallback based on category or name
    String productName = (sspData['name'] ?? '').toLowerCase();
    String category = (sspData['category'] ?? '').toLowerCase();

    // Smart mapping based on product name/category
    if (productName.contains('pork')) return 'assets/images/pork.jpg';
    if (productName.contains('dhal') || productName.contains('dal'))
      return 'assets/images/dhal.jpg';
    if (productName.contains('green gram'))
      return 'assets/images/green_gram.jpg';
    if (productName.contains('beef')) return 'assets/images/beef.jpg';
    if (productName.contains('banana')) return 'assets/images/bananas.jpg';
    if (productName.contains('carrot')) return 'assets/images/carrots.jpg';
    if (productName.contains('tomato')) return 'assets/images/tomatoes.jpg';
    if (productName.contains('leek')) return 'assets/images/leeks.jpg';
    if (productName.contains('rice')) {
      if (productName.contains('nadu')) return 'assets/images/nadu_rice.jpg';
      if (productName.contains('samba')) return 'assets/images/samba_rice.jpg';
      return 'assets/images/samba_rice.jpg'; // Default rice
    }
    if (productName.contains('milk')) return 'assets/images/anchor_milk.jpg';
    if (productName.contains('butter')) return 'assets/images/butter.jpg';
    if (productName.contains('cheese')) return 'assets/images/cheese.jpg';
    if (productName.contains('curd')) return 'assets/images/curd.jpg';
    if (productName.contains('bread')) return 'assets/images/bread.jpg';
    if (productName.contains('mango')) return 'assets/images/mangoes.jpg';
    if (productName.contains('papaya')) return 'assets/images/papaya.jpg';
    if (productName.contains('pineapple')) return 'assets/images/pineapple.jpg';
    if (productName.contains('bean')) return 'assets/images/beans.jpg';
    if (productName.contains('brinjal') || productName.contains('eggplant'))
      return 'assets/images/brinjals.jpg';

    // Category-based fallbacks
    if (category.contains('meat')) return 'assets/images/meat.webp';
    if (category.contains('dairy')) return 'assets/images/dairy.jpeg';
    if (category.contains('fruit')) return 'assets/images/fruit.jpeg';
    if (category.contains('vegetable')) return 'assets/images/vegetables.webp';
    if (category.contains('grain') || category.contains('cereal'))
      return 'assets/images/grains.jpeg';
    if (category.contains('bakery')) return 'assets/images/bakery.jpg';

    // Default fallback
    return 'assets/images/vegetables.webp';
  }

  double _parsePrice(dynamic price) {
    if (price is String) {
      return double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
    return (price ?? 0.0).toDouble();
  }

  double _parseRating(dynamic rating) {
    if (rating is String) {
      return double.tryParse(rating) ?? 0.0;
    }
    return (rating ?? 0.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSP Products Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSSPProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // SSP Status Card
          _buildSSPStatusCard(),

          // Products List
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  Widget _buildSSPStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'SSP Connection Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Platform: ${kIsWeb ? "Web Browser" : "Mobile App"}'),
          Text('Endpoint: $_sspBaseUrl'),
          if (_sspInfo != null)
            Text('Status: ${_sspInfo!['status'] ?? 'Connected'}'),
          Text('Products Loaded: ${_sspProducts.length}'),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching products from SSP...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load SSP products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSSPProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sspProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products found on SSP', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _sspProducts.length,
      itemBuilder: (context, index) {
        final product = _sspProducts[index];
        return ProductCard(
          product: product,
          showAddToCart: false, // Disable cart for demo
        );
      },
    );
  }
}
