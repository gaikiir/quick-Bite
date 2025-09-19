import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_bite/screens/models/category_model.dart';
import 'package:quick_bite/screens/models/product_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dynamic categories from Firestore
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];

  // Loading states
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;

  // Error states
  String _categoriesError = '';
  String _productsError = '';

  // Stream subscriptions for proper cleanup
  StreamSubscription<QuerySnapshot>? _categoriesSubscription;
  StreamSubscription<QuerySnapshot>? _productsSubscription;

  // Disposal flag
  bool _isDisposed = false;

  // Getters
  List<CategoryModel> get categories => _categories
    ..sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    ); // Always return sorted by newest first
  List<ProductModel> get products => _products;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingProducts => _isLoadingProducts;
  String get categoriesError => _categoriesError;
  String get productsError => _productsError;

  // Computed getters for backward compatibility
  bool get isLoading => _isLoadingCategories;
  String get error => _categoriesError;
  List<CategoryModel> get availableCategories =>
      _categories.where((cat) => cat.isAvailable).toList()..sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      ); // Sort by newest first

  // Initialize dynamic categories stream from Firestore
  void initCategoriesStream() {
    if (_isDisposed || _categoriesSubscription != null) {
      debugPrint('initCategoriesStream: Already initialized or disposed');
      return;
    }

    debugPrint('initCategoriesStream: Initializing categories stream');
    // Cancel existing subscription if any
    _categoriesSubscription?.cancel();

    _isLoadingCategories = true;
    _categoriesError = '';
    if (!_isDisposed) notifyListeners();

    try {
      _categoriesSubscription = _firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;

              try {
                final parsedCategories = snapshot.docs
                    .map((doc) {
                      try {
                        return CategoryModel.fromJson(doc.data());
                      } catch (e) {
                        // Log the error and skip this document
                        debugPrint(
                          'Error parsing category document ${doc.id}: $e',
                        );
                        return null;
                      }
                    })
                    .where((category) => category != null)
                    .cast<CategoryModel>()
                    .toList();

                // Remove duplicates based on categoryId
                final uniqueCategories = <String, CategoryModel>{};
                final nameDuplicates = <String, List<CategoryModel>>{};

                for (final category in parsedCategories) {
                  // Check for name duplicates
                  if (!nameDuplicates.containsKey(category.categoryName)) {
                    nameDuplicates[category.categoryName] = [];
                  }
                  nameDuplicates[category.categoryName]!.add(category);

                  // Deduplicate by ID (keep the most recent)
                  if (uniqueCategories.containsKey(category.categoryId)) {
                    debugPrint(
                      'Duplicate category ID found: ${category.categoryName} (ID: ${category.categoryId})',
                    );
                    // Keep the one with the most recent createdAt
                    final existing = uniqueCategories[category.categoryId]!;
                    if (category.createdAt.isAfter(existing.createdAt)) {
                      uniqueCategories[category.categoryId] = category;
                    }
                  } else {
                    uniqueCategories[category.categoryId] = category;
                  }
                }

                // Log name duplicates
                for (final entry in nameDuplicates.entries) {
                  if (entry.value.length > 1) {
                    debugPrint(
                      'Categories with same name "${entry.key}": ${entry.value.length} instances',
                    );
                    for (final cat in entry.value) {
                      debugPrint(
                        '  - ID: ${cat.categoryId}, Created: ${cat.createdAt}',
                      );
                    }
                  }
                }

                _categories = uniqueCategories.values.toList();
                _isLoadingCategories = false;
                _categoriesError = '';
                if (!_isDisposed) notifyListeners();
              } catch (parseError) {
                _categoriesError = 'Error parsing category data: $parseError';
                _isLoadingCategories = false;
                if (!_isDisposed) notifyListeners();
              }
            },
            onError: (error) {
              if (_isDisposed) return;

              _categoriesError = 'Failed to load categories: $error';
              _isLoadingCategories = false;
              if (!_isDisposed) notifyListeners();
            },
            onDone: () {
              // Stream completed
            },
          );
    } catch (error) {
      if (_isDisposed) return;

      _categoriesError = 'Failed to initialize categories: $error';
      _isLoadingCategories = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // Load dynamic products for a specific category from Firestore
  void getProductsForCategory(String categoryId) {
    if (_isDisposed) return;

    // Find the category name from the categoryId
    final category = _categories.firstWhere(
      (cat) => cat.categoryId == categoryId,
      orElse: () => CategoryModel(
        categoryId: categoryId,
        categoryName: '',
        categoryDescription: '',
        categoryImage: '',
        isAvailable: true,
      ),
    );

    final categoryName = category.categoryName;
    if (categoryName.isEmpty) {
      _productsError = 'Category not found';
      _isLoadingProducts = false;
      if (!_isDisposed) notifyListeners();
      return;
    }

    // Cancel existing subscription
    _productsSubscription?.cancel();

    _isLoadingProducts = true;
    _productsError = '';
    if (!_isDisposed) notifyListeners();

    try {
      _productsSubscription = _firestore
          .collection('products')
          .where('productCategory', isEqualTo: categoryName)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;

              try {
                _products = snapshot.docs
                    .map((doc) {
                      try {
                        return ProductModel.fromJson(doc.data());
                      } catch (e) {
                        // Log the error and skip this document
                        debugPrint(
                          'Error parsing product document ${doc.id}: $e',
                        );
                        return null;
                      }
                    })
                    .where((product) => product != null)
                    .cast<ProductModel>()
                    .toList();
                _isLoadingProducts = false;
                _productsError = '';
                if (!_isDisposed) notifyListeners();
              } catch (parseError) {
                _productsError = 'Error parsing product data: $parseError';
                _isLoadingProducts = false;
                if (!_isDisposed) notifyListeners();
              }
            },
            onError: (error) {
              if (_isDisposed) return;

              final errorString = error.toString();

              // If it's an index error, try fallback query without ordering
              if (errorString.contains('requires an index') ||
                  errorString.contains('failed-precondition')) {
                _tryFallbackProductQuery(categoryName);
              } else {
                _productsError = 'Failed to load products: $error';
                _isLoadingProducts = false;
                if (!_isDisposed) notifyListeners();
              }
            },
            onDone: () {
              // Stream completed
            },
          );
    } catch (error) {
      if (_isDisposed) return;

      _productsError = 'Failed to initialize products: $error';
      _isLoadingProducts = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // Fallback query without ordering when index is not available
  void _tryFallbackProductQuery(String categoryName) {
    try {
      _productsSubscription = _firestore
          .collection('products')
          .where('productCategory', isEqualTo: categoryName)
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;

              try {
                final products = snapshot.docs
                    .map((doc) {
                      try {
                        return ProductModel.fromJson(doc.data());
                      } catch (e) {
                        debugPrint(
                          'Error parsing product document ${doc.id}: $e',
                        );
                        return null;
                      }
                    })
                    .where((product) => product != null)
                    .cast<ProductModel>()
                    .toList();

                // Sort in memory since we can't order in query
                products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                _products = products;
                _isLoadingProducts = false;
                _productsError = '';
                if (!_isDisposed) notifyListeners();
              } catch (parseError) {
                _productsError = 'Error parsing product data: $parseError';
                _isLoadingProducts = false;
                if (!_isDisposed) notifyListeners();
              }
            },
            onError: (error) {
              if (_isDisposed) return;

              _productsError = 'Failed to load products: $error';
              _isLoadingProducts = false;
              if (!_isDisposed) notifyListeners();
            },
          );
    } catch (error) {
      if (_isDisposed) return;

      _productsError = 'Failed to initialize fallback products query: $error';
      _isLoadingProducts = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // Clean up duplicate categories in Firestore (admin function)
  Future<void> cleanupDuplicateCategories() async {
    try {
      debugPrint('Starting duplicate category cleanup...');

      final snapshot = await _firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .get();

      final categoriesByName = <String, List<QueryDocumentSnapshot>>{};
      final categoriesById = <String, QueryDocumentSnapshot>{};

      // Group by name and collect all instances
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final categoryName = data['categoryName']?.toString() ?? '';
        final categoryId = data['categoryId']?.toString() ?? '';

        if (!categoriesByName.containsKey(categoryName)) {
          categoriesByName[categoryName] = [];
        }
        categoriesByName[categoryName]!.add(doc);

        categoriesById[categoryId] = doc;
      }

      // Delete duplicates, keeping only the most recent one for each name
      int deletedCount = 0;
      for (final entry in categoriesByName.entries) {
        final categoryName = entry.key;
        final docs = entry.value;

        if (docs.length > 1) {
          debugPrint(
            'Found ${docs.length} duplicates for category: $categoryName',
          );

          // Sort by createdAt (most recent first)
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = aData != null
                ? DateTime.tryParse(aData['createdAt']?.toString() ?? '') ??
                      DateTime.now()
                : DateTime.now();
            final bTime = bData != null
                ? DateTime.tryParse(bData['createdAt']?.toString() ?? '') ??
                      DateTime.now()
                : DateTime.now();
            return bTime.compareTo(aTime);
          });

          // Keep the first (most recent), delete the rest
          for (int i = 1; i < docs.length; i++) {
            await docs[i].reference.delete();
            deletedCount++;
            debugPrint('Deleted duplicate category: ${docs[i].id}');
          }
        }
      }

      debugPrint(
        'Cleanup completed. Deleted $deletedCount duplicate categories.',
      );

      // Refresh categories after cleanup
      await refreshCategories();
    } catch (error) {
      debugPrint('Error during category cleanup: $error');
      throw Exception('Failed to cleanup duplicate categories: $error');
    }
  }

  // Clear products when navigating away
  void clearProducts() {
    if (_isDisposed) return;

    _productsSubscription?.cancel();
    _productsSubscription = null;
    _products = [];
    _productsError = '';
    _isLoadingProducts = false;
    // Don't notify listeners during cleanup
  }

  // Admin: Create new dynamic category
  Future<void> createCategory({
    required String categoryName,
    required String categoryImage,
    required String description,
  }) async {
    if (_isDisposed) return;

    try {
      final docRef = _firestore.collection('categories').doc();
      final category = CategoryModel(
        categoryId: docRef.id,
        categoryName: categoryName,
        categoryImage: categoryImage,
        categoryDescription: description,
        isAvailable: true,
      );

      await docRef.set(category.toJson());
      // Categories will be updated automatically via stream
    } catch (error) {
      throw Exception('Failed to create category: $error');
    }
  }

  // Admin: Delete dynamic category
  Future<void> deleteCategory(String categoryId) async {
    if (_isDisposed) return;

    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      // Categories will be updated automatically via stream
    } catch (error) {
      throw Exception('Failed to delete category: $error');
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Refresh categories (useful for manual refresh)
  Future<void> refreshCategories() async {
    if (_isDisposed) return;

    try {
      _isLoadingCategories = true;
      _categoriesError = '';
      if (!_isDisposed) notifyListeners();

      final snapshot = await _firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .get();

      if (_isDisposed) return;

      final parsedCategories = snapshot.docs
          .map((doc) {
            try {
              return CategoryModel.fromJson(doc.data());
            } catch (e) {
              // Log the error and skip this document
              debugPrint('Error parsing category document ${doc.id}: $e');
              return null;
            }
          })
          .where((category) => category != null)
          .cast<CategoryModel>()
          .toList();

      // Remove duplicates based on categoryId
      final uniqueCategories = <String, CategoryModel>{};
      final nameDuplicates = <String, List<CategoryModel>>{};

      for (final category in parsedCategories) {
        // Check for name duplicates
        if (!nameDuplicates.containsKey(category.categoryName)) {
          nameDuplicates[category.categoryName] = [];
        }
        nameDuplicates[category.categoryName]!.add(category);

        // Deduplicate by ID (keep the most recent)
        if (uniqueCategories.containsKey(category.categoryId)) {
          debugPrint(
            'Duplicate category ID found in refresh: ${category.categoryName} (ID: ${category.categoryId})',
          );
          // Keep the one with the most recent createdAt
          final existing = uniqueCategories[category.categoryId]!;
          if (category.createdAt.isAfter(existing.createdAt)) {
            uniqueCategories[category.categoryId] = category;
          }
        } else {
          uniqueCategories[category.categoryId] = category;
        }
      }

      // Log name duplicates
      for (final entry in nameDuplicates.entries) {
        if (entry.value.length > 1) {
          debugPrint(
            'Categories with same name "${entry.key}" in refresh: ${entry.value.length} instances',
          );
          for (final cat in entry.value) {
            debugPrint('  - ID: ${cat.categoryId}, Created: ${cat.createdAt}');
          }
        }
      }

      _categories = uniqueCategories.values.toList();
      debugPrint(
        'Refreshed ${parsedCategories.length} categories, showing ${_categories.length} unique categories',
      );
      _isLoadingCategories = false;
      _categoriesError = '';
      if (!_isDisposed) notifyListeners();
    } catch (error) {
      if (_isDisposed) return;

      _categoriesError = 'Failed to refresh categories: $error';
      _isLoadingCategories = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // Force clear and reload categories (for debugging)
  Future<void> forceReloadCategories() async {
    debugPrint(
      'forceReloadCategories: Force clearing and reloading categories',
    );

    // Cancel existing subscription
    _categoriesSubscription?.cancel();
    _categoriesSubscription = null;
    _categories = [];

    // Reinitialize stream
    initCategoriesStream();
  }

  /// Update category image URL
  Future<void> updateCategoryImage(String categoryId, String imageUrl) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'categoryImage': imageUrl,
      });
      // Refresh categories to show updated image
      await refreshCategories();
    } catch (error) {
      debugPrint('Error updating category image: $error');
      rethrow;
    }
  }

  /// Set default images for common categories
  Future<void> setDefaultCategoryImages() async {
    try {
      final categories = await _firestore.collection('categories').get();

      for (final doc in categories.docs) {
        final data = doc.data();
        final categoryName =
            data['categoryName']?.toString().toLowerCase() ?? '';
        final currentImage = data['categoryImage']?.toString() ?? '';

        // Only update if no image is set
        if (currentImage.isEmpty) {
          String defaultImageUrl = '';

          // Set default images based on category name
          if (categoryName.contains('pizza') ||
              categoryName.contains('pizzas')) {
            defaultImageUrl =
                'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop&crop=center';
          } else if (categoryName.contains('asian') ||
              categoryName.contains('asia')) {
            defaultImageUrl =
                'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=center';
          } else if (categoryName.contains('dessert') ||
              categoryName.contains('desserts')) {
            defaultImageUrl =
                'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400&h=300&fit=crop&crop=center';
          } else if (categoryName.contains('beverage') ||
              categoryName.contains('drink')) {
            defaultImageUrl =
                'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&h=300&fit=crop&crop=center';
          } else if (categoryName.contains('healthy') ||
              categoryName.contains('salad')) {
            defaultImageUrl =
                'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=300&fit=crop&crop=center';
          } else if (categoryName.contains('fast') ||
              categoryName.contains('burger')) {
            defaultImageUrl =
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=300&fit=crop&crop=center';
          }

          if (defaultImageUrl.isNotEmpty) {
            await doc.reference.update({'categoryImage': defaultImageUrl});
            debugPrint('Set default image for category: $categoryName');
          }
        }
      }

      // Refresh categories to show updated images
      await refreshCategories();
      debugPrint('Default category images set successfully');
    } catch (error) {
      debugPrint('Error setting default category images: $error');
      rethrow;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _categoriesSubscription?.cancel();
    _productsSubscription?.cancel();
    _categoriesSubscription = null;
    _productsSubscription = null;
    super.dispose();
  }
}
