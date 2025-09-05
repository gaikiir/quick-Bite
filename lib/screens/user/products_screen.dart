import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/provider/cart_provider.dart';
import 'package:quick_bite/screens/provider/product_provider.dart';
import 'package:quick_bite/screens/widgets/cart_badge.dart';
import 'package:quick_bite/screens/widgets/product_tile_with_cart.dart';

class ProductsScreen extends StatefulWidget {
  static const routeName = '/products';

  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize cart when screen loads
    Future.microtask(() {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.initializeCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Cart badge in app bar
          const CartBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('No products available'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh both products and cart
              productProvider.initProductsStream();
              final cartProvider = Provider.of<CartProvider>(
                context,
                listen: false,
              );
              await cartProvider.loadCartItems();
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: productProvider.products.length,
              itemBuilder: (context, index) {
                final product = productProvider.products[index];
                return ProductTileWithCart(product: product);
              },
            ),
          );
        },
      ),

      // Floating cart summary
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartCount == 0) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_cart),
            label: Text(
              '${cartProvider.cartCount} items • \$${cartProvider.totalAmount.toStringAsFixed(2)}',
            ),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }
}
