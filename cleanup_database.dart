import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  print('🔧 Starting manual database cleanup...');

  try {
    // Get the database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'grocery_app.db');

    print('📍 Database path: $path');

    // Open the database
    final db = await openDatabase(path);

    // First, let's see what we have
    print('\n📊 Current database state:');
    final allProducts = await db.query('products', orderBy: 'id');
    print('Total products: ${allProducts.length}');

    // Show products without images
    final productsWithoutImages = await db.query(
      'products',
      where:
          'imageUrl IS NULL OR imageUrl = "" OR imageUrl NOT LIKE "assets/images/%"',
      orderBy: 'id',
    );

    print(
      '\n❌ Products without proper images (${productsWithoutImages.length}):',
    );
    for (final product in productsWithoutImages) {
      print(
        '  ID: ${product['id']}, Name: ${product['name']}, Image: ${product['imageUrl'] ?? "NULL"}',
      );
    }

    // Show products with images
    final productsWithImages = await db.query(
      'products',
      where:
          'imageUrl IS NOT NULL AND imageUrl != "" AND imageUrl LIKE "assets/images/%"',
      orderBy: 'id',
    );

    print('\n✅ Products with proper images (${productsWithImages.length}):');
    for (final product in productsWithImages) {
      print(
        '  ID: ${product['id']}, Name: ${product['name']}, Image: ${product['imageUrl']}',
      );
    }

    // Ask for confirmation
    print(
      '\n🗑️  Do you want to delete the ${productsWithoutImages.length} products without proper images? (y/n)',
    );
    final input = stdin.readLineSync();

    if (input?.toLowerCase() == 'y' || input?.toLowerCase() == 'yes') {
      // Delete products without proper images
      final deletedCount = await db.delete(
        'products',
        where:
            'imageUrl IS NULL OR imageUrl = "" OR imageUrl NOT LIKE "assets/images/%"',
      );

      print('✅ Successfully deleted $deletedCount products!');

      // Show final state
      final finalProducts = await db.query('products', orderBy: 'id');
      print(
        '📊 Final database state: ${finalProducts.length} products remaining',
      );

      // Check for duplicates by name
      final duplicateCheck = await db.rawQuery('''
        SELECT name, COUNT(*) as count 
        FROM products 
        GROUP BY name 
        HAVING COUNT(*) > 1
      ''');

      if (duplicateCheck.isEmpty) {
        print('🎉 No duplicates found! Database is clean.');
      } else {
        print('⚠️  Still have duplicates:');
        for (final dup in duplicateCheck) {
          print('  ${dup['name']}: ${dup['count']} copies');
        }
      }
    } else {
      print('❌ Cleanup cancelled.');
    }

    await db.close();
  } catch (e) {
    print('💥 Error: $e');
  }

  print('\n🏁 Database cleanup script finished.');
}
