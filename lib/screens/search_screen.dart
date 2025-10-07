import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/product_card.dart';
import '../models/models.dart';

class SearchScreen extends StatefulWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String _sortBy = 'name';
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    _performSearch(widget.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final results = dataProvider.searchProducts(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  List<Product> _getFilteredAndSortedResults() {
    var results = _searchResults;

    // Filter by category if selected
    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      results = results.where((product) => 
        product.category == _filterCategory).toList();
    }

    // Sort results
    switch (_sortBy) {
      case 'name':
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                    // Navigate back to home screen when search is cleared
                    Navigator.of(context).pop();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterAndSort(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSort() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Consumer<DataProvider>(
              builder: (context, dataProvider, child) {
                return DropdownButtonFormField<String>(
                  value: _filterCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...dataProvider.categories.map((category) =>
                      DropdownMenuItem<String>(
                        value: category.name,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterCategory = value;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Name')),
                DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                DropdownMenuItem(value: 'rating', child: Text('Rating')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredResults = _getFilteredAndSortedResults();

    if (filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
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
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final product = filteredResults[index];
        return ProductCard(product: product);
      },
    );
  }
}