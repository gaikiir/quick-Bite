import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/widgets/cart_badge.dart';
import 'package:quick_bite/screens/widgets/cart_widgets.dart';
import 'package:quick_bite/screens/widgets/quantity_select.dart';

import '../models/product_model.dart';
import '../provider/product_provider.dart';

class ProductDetailsScreen extends StatelessWidget {
  static const routeName = '/product-details';
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments;

    if (arguments is! ProductModel) {
      return _buildErrorScaffold(context, 'Invalid product data provided');
    }

    final product = arguments;

    // Set the selected product immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.setSelectedProduct(product);
    });

    return ProductDetailsContent(product: product);
  }

  Scaffold _buildErrorScaffold(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              error.isNotEmpty ? error : 'Product not found',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsContent extends StatefulWidget {
  final ProductModel product;
  const ProductDetailsContent({super.key, required this.product});

  @override
  State<ProductDetailsContent> createState() => _ProductDetailsContentState();
}

class _ProductDetailsContentState extends State<ProductDetailsContent> {
  int _selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(widget.product),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductHeader(widget.product),
                  const SizedBox(height: 16),
                  _buildProductInfo(widget.product),
                  const SizedBox(height: 16),
                  _buildProductDescription(widget.product),
                  const SizedBox(height: 24),
                  _buildQuantitySelector(widget.product),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(widget.product),
    );
  }

  Widget _buildSliverAppBar(ProductModel product) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [CartBadge()],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product-${product.productId}',
          child: Image.network(
            product.productImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.productName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '\$${product.productPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductInfo(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildInfoItem(Icons.category, 'Category', product.productCategory),
          const SizedBox(width: 24),
          _buildInfoItem(
            Icons.inventory,
            'Stock',
            '${product.productQuantity} available',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDescription(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(product.productDescription, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildQuantitySelector(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            QuantitySelector(
              quantity: _selectedQuantity,
              onQuantityChanged: (newQuantity) =>
                  setState(() => _selectedQuantity = newQuantity),
              maxQuantity: product.productQuantity,
            ),
            const Spacer(),
            Text(
              'Total: \$${(product.productPrice * _selectedQuantity).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActions(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: AddToCartButton(
          product: product,
          quantity: _selectedQuantity,
          onSuccess: () {},
        ),
      ),
    );
  }
}
