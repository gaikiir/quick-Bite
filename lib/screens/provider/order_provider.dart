import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_bite/screens/models/cart_model.dart';
import 'package:quick_bite/screens/models/order_model.dart';
import 'package:uuid/uuid.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _ordersSubscription;

  // Getters
  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize orders stream for current user
  void initOrdersStream() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in for orders stream');
      return;
    }

    _ordersSubscription?.cancel();
    _ordersSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              _orders = snapshot.docs
                  .map((doc) => OrderModel.fromSnapshot(doc))
                  .toList();

              debugPrint(
                'Loaded ${_orders.length} orders for user ${user.uid}',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notifyListeners();
              });
            } catch (e) {
              debugPrint('Error loading orders: $e');
              _errorMessage = 'Failed to load orders: $e';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notifyListeners();
              });
            }
          },
          onError: (error) {
            debugPrint('Orders stream error: $error');
            _errorMessage = 'Failed to listen to orders: $error';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          },
        );
  }

  // Create a new order
  Future<OrderModel?> createOrder({
    required List<CartModel> cartItems,
    required OrderAddress deliveryAddress,
    required String phoneNumber,
    PaymentMethod paymentMethod = PaymentMethod.mpesa,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Calculate order totals
      final subtotal = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      final deliveryFee = OrderModel.calculateDeliveryFee(deliveryAddress);
      final totalAmount = subtotal + deliveryFee;

      // Create payment info
      final paymentInfo = PaymentInfo(
        method: paymentMethod,
        status: PaymentStatus.pending,
        phoneNumber: phoneNumber,
      );

      // Generate order ID
      final orderId = const Uuid().v4();

      // Create order
      final order = OrderModel(
        orderId: orderId,
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: user.displayName ?? 'Customer',
        userPhone: phoneNumber,
        items: cartItems,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        totalAmount: totalAmount,
        deliveryAddress: deliveryAddress,
        paymentInfo: paymentInfo,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
      );

      // Save to Firestore
      await _firestore.collection('orders').doc(orderId).set(order.toMap());

      // Update current order
      _currentOrder = order;

      debugPrint('Order created successfully: $orderId');

      return order;
    } catch (e) {
      debugPrint('Error creating order: $e');
      _errorMessage = 'Failed to create order: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      _setLoading(true);

      await _firestore.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local order if it's the current order
      if (_currentOrder?.orderId == orderId) {
        _currentOrder = _currentOrder?.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      debugPrint('Order status updated: $orderId -> ${status.name}');
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      _errorMessage = 'Failed to update order status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update payment info
  Future<bool> updatePaymentInfo(
    String orderId,
    PaymentInfo paymentInfo,
  ) async {
    try {
      _setLoading(true);

      await _firestore.collection('orders').doc(orderId).update({
        'paymentInfo': paymentInfo.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local order if it's the current order
      if (_currentOrder?.orderId == orderId) {
        _currentOrder = _currentOrder?.copyWith(
          paymentInfo: paymentInfo,
          updatedAt: DateTime.now(),
        );
      }

      debugPrint('Payment info updated for order: $orderId');
      return true;
    } catch (e) {
      debugPrint('Error updating payment info: $e');
      _errorMessage = 'Failed to update payment info: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      _setLoading(true);

      final updates = {
        'status': OrderStatus.cancelled.name,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (reason != null) {
        updates['adminNotes'] = reason;
      }

      await _firestore.collection('orders').doc(orderId).update(updates);

      debugPrint('Order cancelled: $orderId');
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      _errorMessage = 'Failed to cancel order: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (doc.exists) {
        return OrderModel.fromSnapshot(doc);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      _errorMessage = 'Failed to get order: $e';
      return null;
    }
  }

  // Get user orders with pagination
  Future<List<OrderModel>> getUserOrders({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      Query query = _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user orders: $e');
      _errorMessage = 'Failed to get orders: $e';
      return [];
    }
  }

  // Set current order (for tracking during checkout)
  void setCurrentOrder(OrderModel? order) {
    _currentOrder = order;
    notifyListeners();
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Admin methods for order management
  Future<List<OrderModel>> getAllOrders({
    OrderStatus? statusFilter,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection('orders');

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => OrderModel.fromSnapshot(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all orders: $e');
      _errorMessage = 'Failed to get orders: $e';
      return [];
    }
  }

  // Stream all orders for admin
  Stream<List<OrderModel>> getAllOrdersStream({OrderStatus? statusFilter}) {
    try {
      Query query = _firestore.collection('orders');

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      return query
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => OrderModel.fromSnapshot(doc))
                .toList(),
          );
    } catch (e) {
      debugPrint('Error creating orders stream: $e');
      return Stream.error('Failed to load orders: $e');
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
