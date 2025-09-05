import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/admin/add_product_screen.dart';
import 'package:quick_bite/screens/widgets/product_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products'), elevation: 0),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          return LayoutBuilder(
            builder: (context, parentConstraints) {
              final screenWidth = parentConstraints.maxWidth;
              final crossAxisCount = screenWidth > 900
                  ? 4
                  : screenWidth > 600
                  ? 3
                  : 2;

              final spacing = screenWidth * 0.02; // 2% of screen width
              final availableWidth =
                  screenWidth - (spacing * (crossAxisCount + 1));
              final itemWidth = availableWidth / crossAxisCount;
              final itemHeight = itemWidth * 1.6; // 60% taller than wide

              if (provider.isLoading) {
                return GridView.builder(
                  padding: EdgeInsets.all(spacing),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: itemWidth / itemHeight,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => const ProductShimmer(),
                );
              }

              if (provider.error.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.error,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.initProductsStream(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Get unique categories from products
              final categories = provider.products
                  .map((product) => product.productCategory)
                  .toSet()
                  .toList();

              return Column(
                children: [
                  // Search and Filter Card
                  Card(
                    margin: EdgeInsets.all(spacing),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(spacing),
                      child: Column(
                        children: [
                          // Search bar
                          TextField(
                            onChanged: (query) =>
                                provider.searchProducts(query),
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(height: spacing),
                          // Category filter
                          DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Filter by Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.category),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('All Categories'),
                              ),
                              ...categories.map((category) {
                                final categoryStr = category.toString();
                                return DropdownMenuItem(
                                  value: categoryStr,
                                  child: Text(categoryStr),
                                );
                              }).toList(),
                            ],
                            onChanged: (category) {
                              setState(() => selectedCategory = category);
                              provider.filterByCategory(category ?? '');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Products grid
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(spacing),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: itemWidth / itemHeight,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                      ),
                      itemCount: provider.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = provider.filteredProducts[index];
                        return ProductCard(
                          product: product,
                          onEditPressed: () async {
                            final edited = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddProductScreen(product: product),
                              ),
                            );
                            if (edited == true) {
                              provider.initProductsStream();
                            }
                          },
                          onDeletePressed: () async {
                            await provider.deleteProduct(product.productId);
                            provider.initProductsStream();
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
