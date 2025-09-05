import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/models/product_model.dart';
import 'package:quick_bite/screens/provider/cart_provider.dart';

class AddToCartButton extends StatefulWidget {
  final ProductModel product;
  final String? selectedSize;
  final String? selectedColor;
  final int quantity;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const AddToCartButton({
    super.key,
    required this.product,
    this.selectedSize,
    this.selectedColor,
    this.quantity = 1,
    this.onSuccess,
    this.onError,
  });

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  bool _isLoading = false;

  Future<void> _addToCart() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      await cartProvider.addToCart(
        product: widget.product,
        quantity: widget.quantity,
        selectedSize: widget.selectedSize,
        selectedColor: widget.selectedColor,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.productName} added to cart!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );

        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        widget.onError?.call();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isInCart = cartProvider.isInCart(widget.product.productId);

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _addToCart,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isInCart ? Icons.check_circle : Icons.add_shopping_cart,
                    size: 20,
                  ),
            label: Text(
              _isLoading
                  ? 'Adding...'
                  : isInCart
                  ? 'Added to Cart'
                  : 'Add to Cart',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isInCart
                  ? Colors.green
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        );
      },
    );
  }
}
