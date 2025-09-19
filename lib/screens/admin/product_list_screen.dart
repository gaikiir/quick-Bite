import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/admin/add_product_screen.dart';

import '../../widgets/product_grid_card.dart';
import '../../widgets/product_list_card.dart';
import '../models/product_model.dart';
import '../provider/product_provider.dart';
import '../widgets/product_shimmer.dart';

class ProductListScreen extends StatefulWidget {
  static const routeName = 'productScreen';
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? selectedCategory;
  String searchQuery = '';
  bool showGridView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(showGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => showGridView = !showGridView),
            tooltip: showGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ProductProvider>().initProductsStream(),
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Statistics Cards
              _buildStatisticsCards(provider),

              // Search and Filter Section
              _buildSearchAndFilterSection(provider),

              // Products Display
              Expanded(child: _buildProductsDisplay(provider)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildStatisticsCards(ProductProvider provider) {
    final totalProducts = provider.products.length;
    final activeProducts = provider.products
        .where((p) => p.productQuantity > 0)
        .length;
    final categories = provider.products
        .map((p) => p.productCategory)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildStatCard(
            title: 'Total Products',
            value: totalProducts.toString(),
            icon: Icons.inventory,
            color: Colors.blue,
          ),
          _buildStatCard(
            title: 'Active Products',
            value: activeProducts.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatCard(
            title: 'Categories',
            value: categories.toString(),
            icon: Icons.category,
            color: Colors.orange,
          ),
          _buildStatCard(
            title: 'Out of Stock',
            value: provider.products
                .where((p) => p.productQuantity == 0)
                .length
                .toString(),
            icon: Icons.warning,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(ProductProvider provider) {
    final categories = provider.products
        .map((product) => product.productCategory)
        .toSet()
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (query) {
              setState(() => searchQuery = query);
              provider.searchProducts(query);
            },
            decoration: InputDecoration(
              hintText: 'Search products by name, description...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => searchQuery = '');
                        provider.searchProducts('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Filters Row
          Row(
            children: [
              // Category Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((category) {
                      final categoryStr = category.toString();
                      return DropdownMenuItem(
                        value: categoryStr,
                        child: Text(categoryStr),
                      );
                    }),
                  ],
                  onChanged: (category) {
                    setState(() => selectedCategory = category);
                    provider.filterByCategory(category ?? '');
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Active Only'),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive Only'),
                    ),
                  ],
                  onChanged: (status) {
                    // TODO: Implement status filtering
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsDisplay(ProductProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingView();
    }

    if (provider.error.isNotEmpty) {
      return _buildErrorView(provider);
    }

    if (provider.filteredProducts.isEmpty) {
      return _buildEmptyView();
    }

    return showGridView ? _buildGridView(provider) : _buildListView(provider);
  }

  Widget _buildLoadingView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ProductShimmer(),
    );
  }

  Widget _buildErrorView(ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load products',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            provider.error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.initProductsStream(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty || selectedCategory != null
                ? 'No products found'
                : 'No products available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || selectedCategory != null
                ? 'Try adjusting your search or filters'
                : 'Start by adding your first product',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isEmpty && selectedCategory == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridView(ProductProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = provider.filteredProducts[index];
        return _buildProductGridCard(product, provider);
      },
    );
  }

  Widget _buildListView(ProductProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = provider.filteredProducts[index];
        return _buildProductListCard(product, provider);
      },
    );
  }

  Widget _buildProductGridCard(ProductModel product, ProductProvider provider) {
    return ProductGridCard(product: product, provider: provider);
  }

  Widget _buildProductListCard(ProductModel product, ProductProvider provider) {
    return ProductListCard(product: product, provider: provider);
  }
}
