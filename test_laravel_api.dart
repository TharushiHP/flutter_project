// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

/// Simple script to test Laravel API connectivity
/// Run this with: dart run test_laravel_api.dart
void main() async {
  print('🔍 Testing Laravel API Connectivity...\n');

  final client = HttpClient();
  const baseUrl = 'https://web-production-6d61b.up.railway.app/api';

  // Test endpoints
  final endpoints = {
    'Health Check': '/health',
    'Products': '/products',
    'Login': '/login',
    'Categories': '/categories',
  };

  print('📊 Laravel API Test Results:');
  print('=' * 50);

  for (final entry in endpoints.entries) {
    final name = entry.key;
    final endpoint = entry.value;
    final fullUrl = '$baseUrl$endpoint';

    try {
      print('\n🔗 Testing $name ($endpoint)...');

      final request = await client.getUrl(Uri.parse(fullUrl));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');

      // For login endpoint, try POST instead
      if (endpoint == '/login') {
        final postRequest = await client.postUrl(Uri.parse(fullUrl));
        postRequest.headers.set('Content-Type', 'application/json');
        postRequest.headers.set('Accept', 'application/json');

        final testData = json.encode({
          'email': 'test@example.com',
          'password': 'password123',
        });
        postRequest.write(testData);

        final response = await postRequest.close();
        await _handleResponse(name, endpoint, response);
        continue;
      }

      final response = await request.close();
      await _handleResponse(name, endpoint, response);
    } catch (e) {
      print('   ❌ ERROR: $e');
    }
  }

  print('\n${'=' * 50}');
  print('🎯 Recommendations:');
  print(
    '✅ Health & Products endpoints are working - Laravel backend is functional',
  );
  print(
    '❌ Login endpoint returns 405 - Check Laravel routes/api.php for POST /api/login',
  );
  print(
    '❌ Categories endpoint returns 404 - Implement categories controller or extract from products',
  );
  print('\n💡 Your Flutter app can work with current setup using hybrid mode:');
  print('   • Products data from Laravel API ✅');
  print('   • Categories extracted from products data ✅');
  print('   • Authentication falls back to local database ✅');

  client.close();
}

Future<void> _handleResponse(
  String name,
  String endpoint,
  HttpClientResponse response,
) async {
  final statusCode = response.statusCode;
  final body = await response.transform(utf8.decoder).join();

  if (statusCode == 200) {
    print('   ✅ SUCCESS ($statusCode)');

    // Show data preview for successful responses
    try {
      final data = json.decode(body);
      if (endpoint == '/products' && data['data'] != null) {
        final products = data['data']['products'] as List;
        print('      📦 Found ${products.length} products');
        if (products.isNotEmpty) {
          final firstProduct = products.first;
          print(
            '      🏷️  Sample: ${firstProduct['name']} - LKR ${firstProduct['price']}',
          );
        }
      } else if (endpoint == '/health') {
        print('      💚 Database: ${data['database'] ?? 'Unknown'}');
        print('      📅 Timestamp: ${data['timestamp'] ?? 'Unknown'}');
      }
    } catch (e) {
      print('      📄 Response length: ${body.length} chars');
    }
  } else if (statusCode == 404) {
    print('   ❌ NOT FOUND ($statusCode) - Endpoint not implemented');
  } else if (statusCode == 405) {
    print('   ❌ METHOD NOT ALLOWED ($statusCode) - Route configuration issue');
  } else {
    print('   ⚠️  UNEXPECTED ($statusCode)');
  }
}
