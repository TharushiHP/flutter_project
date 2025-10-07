import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔧 Database cleanup tool starting...');
  
  try {
    // Get the database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'grocery_app.db');
    
    print('📍 Database path: $path');
    
    // Open the database
    final db = await openDatabase(path);
    
    // Step 1: Check current state
    final allProducts = await db.query('products', orderBy: 'id');
    print('\n📊 Total products in database: ${allProducts.length}');
    
    // Show products without proper images
    final productsWithoutImages = allProducts.where((product) {
      final imageUrl = product['imageUrl'] as String?;
      return imageUrl == null || 
             imageUrl.isEmpty || 
             !imageUrl.startsWith('assets/images/');
    }).toList();
    
    print('\n❌ Products without proper images (${productsWithoutImages.length}):');
    for (final product in productsWithoutImages) {
      print('  ID: ${product['id']}, Name: ${product['name']}, Image: ${product['imageUrl'] ?? "NULL"}');
    }
    
    // Show products with proper images
    final productsWithImages = allProducts.where((product) {
      final imageUrl = product['imageUrl'] as String?;
      return imageUrl != null && 
             imageUrl.isNotEmpty && 
             imageUrl.startsWith('assets/images/');
    }).toList();
    
    print('\n✅ Products with proper images (${productsWithImages.length}):');
    for (final product in productsWithImages) {
      print('  ID: ${product['id']}, Name: ${product['name']}, Image: ${product['imageUrl']}');
    }
    
    // Step 2: Delete products without proper images
    if (productsWithoutImages.isNotEmpty) {
      print('\n🗑️  Deleting ${productsWithoutImages.length} products without proper images...');
      
      for (final product in productsWithoutImages) {
        await db.delete('products', where: 'id = ?', whereArgs: [product['id']]);
        print('  Deleted: ${product['name']} (ID: ${product['id']})');
      }
      
      print('✅ Successfully deleted ${productsWithoutImages.length} products!');
    } else {
      print('✅ No products need to be deleted. Database is clean!');
    }
    
    // Step 3: Verify final state
    final finalProducts = await db.query('products', orderBy: 'id');
    print('\n📊 Final database state: ${finalProducts.length} products remaining');
    
    // Check for duplicates by name
    final Map<String, int> nameCount = {};
    for (final product in finalProducts) {
      final name = product['name'] as String;
      nameCount[name] = (nameCount[name] ?? 0) + 1;
    }
    
    final duplicates = nameCount.entries.where((entry) => entry.value > 1).toList();
    
    if (duplicates.isEmpty) {
      print('🎉 No duplicates found! Database is clean.');
    } else {
      print('⚠️  Still have duplicates:');
      for (final dup in duplicates) {
        print('  ${dup.key}: ${dup.value} copies');
      }
    }
    
    await db.close();
    
  } catch (e) {
    print('💥 Error: $e');
  }
  
  print('\n🏁 Database cleanup completed!');
}