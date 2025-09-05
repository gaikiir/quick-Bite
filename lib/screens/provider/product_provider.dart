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
  bool _isLoading = false;
  String _error = '';
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get error => _error;

  ProductProvider() {
    initProductsStream();
  }

  // Initialize products stream
  void initProductsStream() {
    _isLoading = true;
    notifyListeners();

    _productsSubscription?.cancel();
    _productsSubscription = _productService.getAllProducts().listen(
      (products) {
        _products = products;
        _filteredProducts = products;
        _error = '';
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
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
