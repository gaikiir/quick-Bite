import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_bite/screens/models/cart_model.dart';
import 'package:quick_bite/screens/models/product_model.dart';
import 'package:uuid/uuid.dart';

class CartProvider with ChangeNotifier {
  List<CartModel> _cartItems = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _cartSubscription;

  CartProvider() {
    debugPrint('CartProvider initialized');
  }

  List<CartModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  int get cartCount => _cartItems.length;

  double get totalAmount {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalQuantity {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  CartModel? getCartItem(String productId) {
    try {
      return _cartItems.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addToCart({
    required ProductModel product,
    int quantity = 1,
    String? selectedSize,
    String? selectedColor,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      debugPrint(
        'Adding to cart: ${product.productName} for user: ${user.uid}',
      );

      final existingItemIndex = _cartItems.indexWhere(
        (item) =>
            item.productId == product.productId &&
            item.selectedSize == selectedSize &&
            item.selectedColor == selectedColor,
      );

      if (existingItemIndex != -1) {
        // Update quantity of existing item
        final newQuantity = _cartItems[existingItemIndex].quantity + quantity;
        debugPrint('Updating existing item quantity to: $newQuantity');
        await updateQuantity(_cartItems[existingItemIndex].cartId, newQuantity);
        return;
      } else {
        final cartId = const Uuid().v4();
        final cartItem = CartModel(
          cartId: cartId,
          productId: product.productId,
          productName: product.productName,
          productImage: product.productImage,
          productPrice: product.productPrice,
          quantity: quantity,
          addedAt: DateTime.now(),
          selectedSize: selectedSize,
          selectedColor: selectedColor,
          userId: user.uid,
        );

        debugPrint('Saving cart item to Firestore: $cartId');

        await _firestore.collection('carts').doc(cartId).set(cartItem.toMap());

        debugPrint('Cart item saved successfully');

        _cartItems.add(cartItem);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String cartId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('carts').doc(cartId).delete();
      _cartItems.removeWhere((item) => item.cartId == cartId);
      notifyListeners();
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String cartId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartId);
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get current cart item to check quantity
      final itemIndex = _cartItems.indexWhere((item) => item.cartId == cartId);
      if (itemIndex == -1) return; // Item not found

      // Update Firestore
      await _firestore.collection('carts').doc(cartId).update({
        'quantity': newQuantity,
      });

      // Update local state
      _cartItems[itemIndex] = _cartItems[itemIndex].copyWith(
        quantity: newQuantity,
      );

      notifyListeners();
    } catch (e) {
      print('Error updating quantity: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final cartSnapshot = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCartItems() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not logged in, clearing cart');
        _cartItems.clear();
        return;
      }

      debugPrint('Loading cart items for user: ${user.uid}');

      // Use simple query without ordering
      final cartSnapshot = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .get();

      debugPrint('Found ${cartSnapshot.docs.length} cart items');

      _cartItems = cartSnapshot.docs
          .map((doc) => CartModel.fromMap(doc.data()))
          .toList();

      // Sort locally by addedAt
      _cartItems.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      debugPrint('Cart loaded: ${_cartItems.length} items');

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart items: $e');
      _cartItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToCartChanges() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel any existing subscription
    _cartSubscription?.cancel();

    // Use simple query without ordering
    _cartSubscription = _firestore
        .collection('carts')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            _cartItems = snapshot.docs
                .map((doc) => CartModel.fromMap(doc.data()))
                .toList();
            // Sort locally by addedAt
            _cartItems.sort((a, b) => b.addedAt.compareTo(a.addedAt));
            notifyListeners();
          },
          onError: (error) {
            print('Error listening to cart changes: $error');
          },
        );
  }

  Future<void> initializeCart() async {
    await loadCartItems();
    listenToCartChanges();
  }

  void disposeCart() {
    _cartSubscription?.cancel();
    _cartItems.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
