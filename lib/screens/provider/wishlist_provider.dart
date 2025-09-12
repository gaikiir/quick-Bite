import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_bite/screens/models/product_model.dart';
import 'package:quick_bite/screens/models/wishlist_model.dart';
import 'package:uuid/uuid.dart';

class WishlistProvider with ChangeNotifier {
  List<WishlistModel> _wishlistItems = [];
  bool _isLoading = false;
  String _error = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _wishlistSubscription;
  Set<String> _wishlistProductIds = {}; // For faster lookups

  WishlistProvider() {
    debugPrint('WishlistProvider initialized');
  }

  // Getters
  List<WishlistModel> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get wishlistCount => _wishlistItems.length;

  // Check if a product is in wishlist (optimized with Set)
  bool isInWishlist(String productId) {
    return _wishlistProductIds.contains(productId);
  }

  // Get wishlist item by product ID
  WishlistModel? getWishlistItem(String productId) {
    try {
      return _wishlistItems.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Add to wishlist
  Future<void> addToWishlist(ProductModel product) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      debugPrint(
        'Adding to wishlist: ${product.productName} for user: ${user.uid}',
      );

      // Check if product already exists in wishlist
      if (isInWishlist(product.productId)) {
        // Product already in wishlist, remove it (toggle functionality)
        final existingItem = getWishlistItem(product.productId);
        if (existingItem != null) {
          await removeFromWishlist(existingItem.wishlistId);
        }
        return;
      }

      // Create new wishlist item
      final wishlistId = const Uuid().v4();
      final wishlistItem = WishlistModel(
        wishlistId: wishlistId,
        productId: product.productId,
        productName: product.productName,
        productImage: product.productImage,
        productPrice: product.productPrice,
        addedAt: DateTime.now(),
        category: product.productCategory,
        isAvailable: true,
        userId: user.uid,
      );

      debugPrint('Saving wishlist item to Firestore: $wishlistId');

      // Save to Firestore root wishlists collection
      final docRef = _firestore.collection('wishlists').doc(wishlistId);

      debugPrint('Saving to path: wishlists/$wishlistId');

      await docRef.set(wishlistItem.toMap());

      debugPrint('Wishlist item saved successfully');

      // Verify the save by reading it back
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        debugPrint('Verified: Wishlist item exists in Firestore');
        debugPrint('Saved data: ${savedDoc.data()}');
      } else {
        debugPrint('Error: Wishlist item not found after save');
      }

      _wishlistItems.add(wishlistItem);
      _wishlistProductIds.add(product.productId);
      _error = '';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add to wishlist: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String wishlistId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Remove from Firestore wishlists collection
      await _firestore.collection('wishlists').doc(wishlistId).delete();

      // Remove from local lists
      final removedItem = _wishlistItems.firstWhere(
        (item) => item.wishlistId == wishlistId,
        orElse: () => WishlistModel(
          wishlistId: '',
          productId: '',
          productName: '',
          productImage: '',
          productPrice: 0,
          addedAt: DateTime.now(),
          userId: '',
        ),
      );
      _wishlistItems.removeWhere((item) => item.wishlistId == wishlistId);
      _wishlistProductIds.remove(removedItem.productId);

      _error = '';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove from wishlist: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove from wishlist by product ID
  Future<void> removeFromWishlistByProductId(String productId) async {
    try {
      final item = getWishlistItem(productId);
      if (item != null) {
        await removeFromWishlist(item.wishlistId);
      }
    } catch (e) {
      _error = 'Failed to remove from wishlist by product ID: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    }
  }

  // Load wishlist items
  Future<void> loadWishlistItems() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not logged in, clearing wishlist');
        _wishlistItems.clear();
        _wishlistProductIds.clear();
        _error = 'Please log in to view your wishlist';
        return;
      }

      debugPrint('Loading wishlist items for user: ${user.uid}');

      final wishlistSnapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: user.uid)
          .get();
      debugPrint('Found ${wishlistSnapshot.docs.length} wishlist items');

      _wishlistItems = wishlistSnapshot.docs
          .map((doc) => WishlistModel.fromMap(doc.data()))
          .toList();

      // Sort by addedAt descending (newest first) since we can't use orderBy in query
      _wishlistItems.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      // Update the product IDs set for fast lookups
      _wishlistProductIds = _wishlistItems
          .map((item) => item.productId)
          .toSet();

      debugPrint('Wishlist loaded: ${_wishlistItems.length} items');

      _error = '';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load wishlist: ${e.toString()}';
      debugPrint(_error);
      _wishlistItems = [];
      _wishlistProductIds.clear();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Listen to wishlist changes
  void listenToWishlistChanges() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('User not logged in, cannot listen to wishlist changes');
      _error = 'Please log in to sync your wishlist';
      notifyListeners();
      return;
    }

    // Cancel any existing subscription
    _wishlistSubscription?.cancel();

    // Listen to changes in wishlists collection for current user
    _wishlistSubscription = _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            _wishlistItems = snapshot.docs
                .map((doc) => WishlistModel.fromMap(doc.data()))
                .toList();

            // Sort by addedAt descending (newest first)
            _wishlistItems.sort((a, b) => b.addedAt.compareTo(a.addedAt));

            _wishlistProductIds = _wishlistItems
                .map((item) => item.productId)
                .toSet();

            _error = '';
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to listen to wishlist changes: $error';
            debugPrint(_error);
            notifyListeners();
          },
        );
  }

  // Initialize wishlist
  Future<void> initializeWishlist() async {
    debugPrint('Initializing wishlist...');
    await loadWishlistItems();
    listenToWishlistChanges();
    debugPrint('Wishlist initialized');
  }

  // Clear wishlist
  Future<void> clearWishlist() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final wishlistSnapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in wishlistSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _wishlistItems.clear();
      _wishlistProductIds.clear();
      _error = '';
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear wishlist: ${e.toString()}';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dispose
  void disposeWishlist() {
    _wishlistSubscription?.cancel();
    _wishlistItems.clear();
    _wishlistProductIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _wishlistSubscription?.cancel();
    super.dispose();
  }
}
