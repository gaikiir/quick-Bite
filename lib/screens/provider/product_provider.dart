import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/cloudinary_service.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String _error = '';
  StreamSubscription<QuerySnapshot>? _productsSubscription;

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get filteredProducts => _filteredProducts;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String get error => _error;

  ProductProvider() {
    // Removed auto-initialization to prevent double initialization
  }

  // Initialize products stream
  void initProductsStream() {
    _isLoading = true;

    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    _productsSubscription?.cancel();
    _productsSubscription = _firestore
        .collection('products')
        .snapshots()
        .listen(
          (querySnapshot) {
            _products = querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['productId'] =
                  doc.id; // Use productId as expected by the model
              return ProductModel.fromJson(data);
            }).toList();
            _filteredProducts = _products;
            _error = '';
            _isLoading = false;

            // Use post frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;

            // Use post frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          },
        );
  }

  // Get product details by ID
  Future<ProductModel?> getProductDetails(String productId) async {
    try {
      _isLoadingDetails = true;
      _error = '';

      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // First check if product exists in current products list
      final existingProduct = _products.firstWhere(
        (product) => product.productId == productId,
        orElse: () => ProductModel.empty(),
      );

      if (existingProduct.productId.isNotEmpty) {
        _selectedProduct = existingProduct;
        _isLoadingDetails = false;

        // Use post frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });

        return existingProduct;
      }

      // If not found locally, fetch from Firestore
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['productId'] = doc.id;
        final product = ProductModel.fromJson(data);
        _selectedProduct = product;
      } else {
        _selectedProduct = null;
      }
      _isLoadingDetails = false;

      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return _selectedProduct;
    } catch (e) {
      _error = e.toString();
      _isLoadingDetails = false;
      _selectedProduct = null;

      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return null;
    }
  }

  // Set selected product (for when passing product object directly)
  void setSelectedProduct(ProductModel product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  // Get updated product data (useful for real-time updates)
  Future<void> refreshProductDetails(String productId) async {
    if (productId.isEmpty) return;
    await getProductDetails(productId);
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  // Create product (admin function - implement as needed)
  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int quantity,
    File? imageFile,
    Uint8List? webImage,
  }) async {
    try {
      _setLoading(true);

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(
          'You must be logged in to create products. Please sign in first.',
        );
      }

      // Upload image to Cloudinary if provided
      String imageUrl = '';
      if (imageFile != null || webImage != null) {
        if (!CloudinaryService.isConfigured()) {
          throw Exception(
            'Cloudinary is not configured. Please set up your Cloudinary credentials in cloudinary_config.dart',
          );
        }
        imageUrl =
            await CloudinaryService.uploadImage(
              imageFile: imageFile,
              webImage: webImage,
              fileName:
                  '${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
            ) ??
            '';
      }

      // Create product data
      final productData = {
        'productId': DateTime.now().millisecondsSinceEpoch.toString(),
        'productName': name,
        'productDescription': description,
        'productPrice': price,
        'productCategory': category,
        'productQuantity': quantity,
        'productImage': imageUrl,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add to Firestore
      await _firestore.collection('products').add(productData);

      _setLoading(false);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = '';
    }
    notifyListeners();
  }

  // Helper method to handle errors
  void _handleError(dynamic error) {
    _isLoading = false;
    _error = error.toString();
    notifyListeners();
  }

  // Update product (admin function - implement as needed)
  Future<void> updateProduct(
    ProductModel product, {
    File? newImageFile,
    Uint8List? newWebImage,
  }) async {
    try {
      _setLoading(true);

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(
          'You must be logged in to update products. Please sign in first.',
        );
      }

      String imageUrl = product.productImage;

      // Upload new image if provided
      if (newImageFile != null || newWebImage != null) {
        if (!CloudinaryService.isConfigured()) {
          throw Exception(
            'Cloudinary is not configured. Please set up your Cloudinary credentials in cloudinary_config.dart',
          );
        }
        imageUrl =
            await CloudinaryService.uploadImage(
              imageFile: newImageFile,
              webImage: newWebImage,
              fileName:
                  '${product.productName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
            ) ??
            product.productImage;
      }

      // Create updated product data
      final updatedProduct = ProductModel(
        productId: product.productId,
        productName: product.productName,
        productDescription: product.productDescription,
        productPrice: product.productPrice,
        productCategory: product.productCategory,
        productQuantity: product.productQuantity,
        productImage: imageUrl,
        createdAt: product.createdAt,
      );

      // Update product in Firestore
      await _firestore
          .collection('products')
          .doc(product.productId)
          .update(updatedProduct.toJson());

      // Update selected product if it's the same one being updated
      if (_selectedProduct?.productId == product.productId) {
        _selectedProduct = updatedProduct;
      }

      _setLoading(false);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Delete product (admin function - implement as needed)
  Future<void> deleteProduct(String productId) async {
    try {
      _setLoading(true);

      // Delete from Firestore
      await _firestore.collection('products').doc(productId).delete();

      // Clear selected product if it's the deleted one
      if (_selectedProduct?.productId == productId) {
        _selectedProduct = null;
      }

      _setLoading(false);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Filter products by category
  void filterByCategory(String category) {
    if (category.isEmpty || category == 'All') {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((product) => product.productCategory == category)
          .toList();
    }
    notifyListeners();
  }

  // Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _filteredProducts = _products;
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);

      // Search products locally (or implement Firestore query as needed)
      _filteredProducts = _products.where((product) {
        return product.productName.toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            product.productDescription.toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            product.productCategory.toLowerCase().contains(query.toLowerCase());
      }).toList();

      _setLoading(false);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Clear filters
  void clearFilters() {
    _filteredProducts = _products;
    notifyListeners();
  }
}
