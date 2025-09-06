import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/wishlist_model.dart';
import '../provider/wishlist_provider.dart';

class WishlistIcon extends StatelessWidget {
  final String productId;
  final Color? color;
  final double? size;

  const WishlistIcon({
    super.key,
    required this.productId,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isInWishlist = wishlistProvider.isInWishlist(productId);
        return Icon(
          isInWishlist ? Icons.favorite : Icons.favorite_border,
          color: isInWishlist ? Colors.red : color ?? Colors.grey,
          size: size,
        );
      },
    );
  }
}

class WishlistButton extends StatelessWidget {
  final String productId;
  final ProductModel product;
  final VoidCallback? onToggle;

  const WishlistButton({
    super.key,
    required this.productId,
    required this.product,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isInWishlist = wishlistProvider.isInWishlist(productId);
        return IconButton(
          icon: WishlistIcon(productId: productId),
          onPressed: () async {
            try {
              debugPrint(
                'Wishlist button pressed for product: ${product.productId}',
              );
              await wishlistProvider.addToWishlist(product);
              onToggle?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isInWishlist
                          ? 'Removed from wishlist'
                          : 'Added to wishlist',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error adding to wishlist: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}

class WishlistItemCard extends StatelessWidget {
  final WishlistModel wishlistItem;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const WishlistItemCard({
    super.key,
    required this.wishlistItem,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  wishlistItem.productImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wishlistItem.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${wishlistItem.productPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (wishlistItem.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        wishlistItem.category!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              // Remove Button
              IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}
