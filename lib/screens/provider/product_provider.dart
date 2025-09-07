import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String _error = '';
  StreamSubscription<List<ProductModel>>? _productsSubscription;

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
    _productsSubscription = _productService.getAllProducts().listen(
      (products) {
        _products = products;
        _filteredProducts = products;
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
      notifyListeners();

      // First check if product exists in current products list
      final existingProduct = _products.firstWhere(
        (product) => product.productId == productId,
        orElse: () => ProductModel.empty(),
      );

      if (existingProduct.productId.isNotEmpty) {
        _selectedProduct = existingProduct;
        _isLoadingDetails = false;
        notifyListeners();
        return existingProduct;
      }

      // If not found locally, fetch from service
      final product = await _productService.getProductById(productId);
      _selectedProduct = product;
      _isLoadingDetails = false;
      notifyListeners();

      return product;
    } catch (e) {
      _error = e.toString();
      _isLoadingDetails = false;
      _selectedProduct = null;
      notifyListeners();
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

  // Create product
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
      await _productService.createProduct(
        name: name,
        description: description,
        price: price,
        category: category,
        quantity: quantity,
        imageFile: imageFile,
        webImage: webImage,
      );
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

  // Update product
  Future<void> updateProduct(
    ProductModel product, {
    File? newImageFile,
    Uint8List? newWebImage,
  }) async {
    try {
      _setLoading(true);
      await _productService.updateProduct(
        product,
        newImageFile: newImageFile,
        newWebImage: newWebImage,
      );

      // Update selected product if it's the same one being updated
      if (_selectedProduct?.productId == product.productId) {
        _selectedProduct = product;
      }

      _setLoading(false);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      await _productService.deleteProduct(productId);

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
      _filteredProducts = await _productService.searchProducts(query);
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
