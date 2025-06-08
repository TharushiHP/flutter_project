import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> user = {
      'Full Name': 'Regulus Black',
      'Email': 'reg@example.com',
      'Phone': '1234567890',
      'Username': 'rab',
    };

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children:
            user.entries.map((e) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(title: Text(e.key), subtitle: Text(e.value)),
              );
            }).toList(),
      ),
    );
  }
}
