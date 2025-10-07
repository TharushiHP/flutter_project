import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SSPDebugScreen extends StatefulWidget {
  const SSPDebugScreen({super.key});

  @override
  State<SSPDebugScreen> createState() => _SSPDebugScreenState();
}

class _SSPDebugScreenState extends State<SSPDebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  static const String _sspBaseUrl =
      'https://web-production-6d61b.up.railway.app';

  @override
  void initState() {
    super.initState();
    _runSSPDiagnostics();
  }

  Future<void> _runSSPDiagnostics() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Starting SSP diagnostics...\n';
      _debugOutput += 'Platform: ${kIsWeb ? "Web Browser" : "Mobile App"}\n';
      _debugOutput += 'Base URL: $_sspBaseUrl\n\n';
    });

    await _testEndpoint('/api/health', 'Health Check');
    await _testEndpoint('/api/products', 'Products');
    await _testEndpoint('/api/categories', 'Categories');

    // Test basic connectivity
    await _testBasicConnectivity();

    setState(() {
      _isLoading = false;
      _debugOutput += '\n✅ Diagnostics completed!';
    });
  }

  Future<void> _testEndpoint(
    String endpoint,
    String name, {
    String method = 'GET',
  }) async {
    try {
      setState(() {
        _debugOutput += '🔍 Testing $name ($endpoint)...\n';
      });

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (kIsWeb) {
        headers['Access-Control-Allow-Origin'] = '*';
      }

      http.Response response;

      if (method == 'POST') {
        response = await http
            .post(
              Uri.parse('$_sspBaseUrl$endpoint'),
              headers: headers,
              body: json.encode({
                'email': 'test@example.com',
                'password': 'password',
              }),
            )
            .timeout(const Duration(seconds: 15));
      } else {
        response = await http
            .get(Uri.parse('$_sspBaseUrl$endpoint'), headers: headers)
            .timeout(const Duration(seconds: 15));
      }

      setState(() {
        _debugOutput += '   ✅ Status: ${response.statusCode}\n';
        _debugOutput += '   📋 Headers: ${response.headers}\n';

        try {
          final data = json.decode(response.body);
          final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
          _debugOutput += '   📄 Response:\n$prettyJson\n';
        } catch (e) {
          _debugOutput +=
              '   📄 Raw Response: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}\n';
        }

        _debugOutput += '\n';
      });
    } catch (e) {
      setState(() {
        _debugOutput += '   ❌ Error: $e\n';

        // Add specific error explanations
        if (e.toString().contains('TimeoutException')) {
          _debugOutput +=
              '   💡 This might be a timeout issue - the server is taking too long to respond.\n';
        } else if (e.toString().contains('SocketException')) {
          _debugOutput += '   💡 This is a network connectivity issue.\n';
        } else if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
          _debugOutput +=
              '   💡 This is likely a CORS issue on web. The server needs to allow web requests.\n';
        }

        _debugOutput += '\n';
      });
    }
  }

  Future<void> _testBasicConnectivity() async {
    setState(() {
      _debugOutput += '🌐 Testing basic connectivity...\n';
    });

    try {
      final response = await http
          .get(Uri.parse(_sspBaseUrl))
          .timeout(const Duration(seconds: 10));

      setState(() {
        _debugOutput +=
            '   ✅ Basic connection successful (${response.statusCode})\n';
        _debugOutput += '   📋 Server headers: ${response.headers}\n\n';
      });
    } catch (e) {
      setState(() {
        _debugOutput += '   ❌ Basic connection failed: $e\n\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSP Debug'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runSSPDiagnostics,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _debugOutput,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
