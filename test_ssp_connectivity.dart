import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing SSP Connectivity...\n');

  const String sspUrl = 'https://web-production-6d61b.up.railway.app';

  // Test 1: Basic connectivity
  print('📡 Test 1: Basic connectivity');
  try {
    final response = await http
        .get(Uri.parse(sspUrl))
        .timeout(const Duration(seconds: 10));
    print('✅ Basic connection: ${response.statusCode}');
    print('📋 Server: ${response.headers['server'] ?? 'Unknown'}');
  } catch (e) {
    print('❌ Basic connection failed: $e');
  }

  print('\n📡 Test 2: Health endpoint');
  try {
    final response = await http
        .get(
          Uri.parse('$sspUrl/api/health'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    print('✅ Health check: ${response.statusCode}');
    print('📄 Response: ${response.body}');
  } catch (e) {
    print('❌ Health check failed: $e');
  }

  print('\n📡 Test 3: Products endpoint');
  try {
    final response = await http
        .get(
          Uri.parse('$sspUrl/api/products'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    print('✅ Products: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map &&
          data.containsKey('data') &&
          data['data']['products'] is List) {
        final products = data['data']['products'] as List;
        print('📦 Found ${products.length} products');

        if (products.isNotEmpty) {
          final firstProduct = products.first;
          print(
            '🔍 Sample product: ${firstProduct['name']} - \$${firstProduct['price']}',
          );
        }
      }
    }
  } catch (e) {
    print('❌ Products failed: $e');
  }

  print('\n🏁 Test completed!');
}
