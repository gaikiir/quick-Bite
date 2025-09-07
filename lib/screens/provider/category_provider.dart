import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_bite/screens/models/categoryModel.dart';
import 'package:quick_bite/screens/models/product_model.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCategory = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _categoryProductsSubscription;

  // Products for selected category
  List<ProductModel> _categoryProducts = [];
  bool _isLoadingProducts = false;
  String _productsError = '';

  CategoryProvider() {
    debugPrint('CategoryProvider initialized');
    // Removed auto-initialization to prevent double initialization
  }

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get selectedCategory => _selectedCategory;
  int get categoriesCount => _categories.length;

  // Products getters
  List<ProductModel> get categoryProducts => _categoryProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  String get productsError => _productsError;

  // Check if products are already loaded for a category (kept for compatibility)
  bool hasProductsForCategory(String categoryName) {
    return _selectedCategory == categoryName && _categoryProducts.isNotEmpty;
  }

  // Get available categories (only active ones)
  List<CategoryModel> get availableCategories =>
      _categories.where((category) => category.isAvailable).toList();

  // Subscribe to products for a specific category (real-time updates)
  Future<void> fetchProductsForCategory(String categoryName) async {
    _subscribeToCategoryProducts(categoryName);
  }

  void _subscribeToCategoryProducts(String categoryName) {
    _categoryProductsSubscription?.cancel();
    _isLoadingProducts = true;
    _productsError = '';
    _selectedCategory = categoryName;
    _categoryProducts = [];

    notifyListeners();

    debugPrint('🔍 Subscribing to products for category: $categoryName');

    _categoryProductsSubscription = _firestore
        .collection('products')
        .where('productCategory', isEqualTo: categoryName)
        .snapshots()
        .listen(
          (snapshot) {
            _categoryProducts = snapshot.docs
                .map((doc) => ProductModel.fromJson(doc.data()))
                .toList();
            _isLoadingProducts = false;
            _productsError = '';
            debugPrint(
              '✅ Live products: ${_categoryProducts.length} for $categoryName',
            );

            notifyListeners();
          },
          onError: (e) {
            _productsError = 'Failed to load products: $e';
            _isLoadingProducts = false;
            debugPrint('❌ Error subscribing products for category: $e');

            notifyListeners();
          },
        );
  }

  // (Sample data methods removed - use Firebase console or admin panel to add data)

  // Get products count for a category
  Future<int> getProductsCountForCategory(String categoryName) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('productCategory', isEqualTo: categoryName)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting products count for category: $e');
      return 0;
    }
  }

  // Refresh products for a specific category (re-subscribe)
  Future<void> refreshProductsForCategory(String categoryName) async {
    debugPrint('🔄 Re-subscribing products for category: $categoryName');
    _subscribeToCategoryProducts(categoryName);
  }

  // Clear category products
  void clearCategoryProducts() {
    _categoryProducts = [];
    _selectedCategory = '';
    _productsError = '';
    _categoryProductsSubscription?.cancel();
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Handle errors
  void _handleError(Object error) {
    _error = error.toString();
    _isLoading = false;
    debugPrint('CategoryProvider Error: $_error');
    notifyListeners();
  }

  // Initialize categories stream
  void initCategoriesStream() {
    _categoriesSubscription?.cancel();
    _categoriesSubscription = _firestore
        .collection('categories')
        .orderBy('categoryName')
        .snapshots()
        .listen((snapshot) {
          _categories = snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data()))
              .toList();
          _error = '';
          debugPrint('Categories loaded: ${_categories.length}');
          notifyListeners();
        }, onError: _handleError);
  }

  // Create a new category
  Future<void> createCategory({
    required String categoryName,
    required String categoryImage,
    String? description,
  }) async {
    try {
      _setLoading(true);

      final categoryId = _firestore.collection('categories').doc().id;
      final now = DateTime.now();

      final category = CategoryModel(
        categoryId: categoryId,
        categoryName: categoryName,
        categoryImage: categoryImage,
        description: description,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .set(category.toMap());

      debugPrint('Category created: $categoryName');
      _error = '';
    } catch (e) {
      _handleError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      _setLoading(true);

      final updatedCategory = category.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('categories')
          .doc(category.categoryId)
          .update(updatedCategory.toMap());

      debugPrint('Category updated: ${category.categoryName}');
      _error = '';
    } catch (e) {
      _handleError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      _setLoading(true);

      await _firestore.collection('categories').doc(categoryId).delete();

      debugPrint('Category deleted: $categoryId');
      _error = '';
    } catch (e) {
      _handleError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle category availability
  Future<void> toggleCategoryAvailability(String categoryId) async {
    try {
      final category = _categories.firstWhere(
        (cat) => cat.categoryId == categoryId,
      );

      final updatedCategory = category.copyWith(
        isAvailable: !category.isAvailable,
        updatedAt: DateTime.now(),
      );

      await updateCategory(updatedCategory);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Set selected category
  void setSelectedCategory(String categoryName) {
    _selectedCategory = categoryName;
    debugPrint('Selected category: $categoryName');
    notifyListeners();
  }

  // Clear selected category
  void clearSelectedCategory() {
    _selectedCategory = '';
    debugPrint('Category selection cleared');
    notifyListeners();
  }

  // Get category by ID
  CategoryModel? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere(
        (category) => category.categoryId == categoryId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get category by name
  CategoryModel? getCategoryByName(String categoryName) {
    try {
      return _categories.firstWhere(
        (category) =>
            category.categoryName.toLowerCase() == categoryName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get category names for dropdown
  List<String> get categoryNames =>
      _categories.map((category) => category.categoryName).toList();

  // Clear errors
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Initialize with sample data (for development only - use Firebase console for production)
  Future<void> initializeSampleCategories() async {
    try {
      final sampleCategories = [
        {
          'categoryName': 'Fast Food',
          'categoryImage':
              'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=500',
          'description': 'Quick and delicious fast food options',
        },
        {
          'categoryName': 'Pizza',
          'categoryImage':
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=500',
          'description': 'Fresh pizzas with amazing toppings',
        },
        {
          'categoryName': 'Desserts',
          'categoryImage':
              'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=500',
          'description': 'Sweet treats and desserts',
        },
        {
          'categoryName': 'Beverages',
          'categoryImage':
              'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=500',
          'description': 'Refreshing drinks and beverages',
        },
        {
          'categoryName': 'Healthy',
          'categoryImage':
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
          'description': 'Nutritious and healthy food options',
        },
        {
          'categoryName': 'Asian',
          'categoryImage':
              'https://images.unsplash.com/photo-1563379091339-03246963d4d6?w=500',
          'description': 'Authentic Asian cuisine',
        },
      ];

      for (final categoryData in sampleCategories) {
        await createCategory(
          categoryName: categoryData['categoryName']!,
          categoryImage: categoryData['categoryImage']!,
          description: categoryData['description'],
        );
      }

      debugPrint('Sample categories initialized successfully');
    } catch (e) {
      debugPrint('Error initializing sample categories: $e');
    }
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _categoryProductsSubscription?.cancel();
    super.dispose();
  }
}
