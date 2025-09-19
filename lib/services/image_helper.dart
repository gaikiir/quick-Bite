import 'package:flutter/material.dart';

/// Utility class for handling image loading with error fallbacks
class ImageHelper {
  /// Widget builder for handling image loading with fallbacks
  static Widget buildNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Default placeholder
    placeholder ??= Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );

    // Default error widget
    errorWidget ??= Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );

    // Check if URL is valid
    if (imageUrl.isEmpty || !_isValidImageUrl(imageUrl)) {
      return errorWidget;
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return placeholder!;
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image loading error: $error');
        return errorWidget!;
      },
    );
  }

  /// Check if URL is a valid image URL
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    // Check if it's a valid URL format
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      return false;
    }

    // Check if it has a valid scheme
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }

    // Check if it has common image extensions
    final lowerPath = uri.path.toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    
    return imageExtensions.any((ext) => lowerPath.endsWith(ext)) ||
           url.contains('cloudinary.com') || // Cloudinary URLs
           url.contains('firebase') || // Firebase Storage URLs
           url.contains('googleusercontent.com'); // Google URLs
  }

  /// Build a cached network image with better error handling
  static Widget buildCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    double borderRadius = 0,
  }) {
    Widget imageWidget = buildNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
    );

    if (borderRadius > 0) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Generate placeholder URLs for development
  static String getPlaceholderUrl(int width, int height, {String? text}) {
    text ??= '${width}x$height';
    return 'https://via.placeholder.com/${width}x$height/CCCCCC/969696?text=$text';
  }
}
