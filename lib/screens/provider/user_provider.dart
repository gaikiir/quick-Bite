import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _statusFilter = 'All';

  List<UserModel> get users => _filteredUsers;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get totalUsers => _users.length;
  int get activeUsers => _users.where((user) => user.status == 'Active').length;
  int get suspendedUsers =>
      _users.where((user) => user.status == 'Suspended').length;
  int get blockedUsers =>
      _users.where((user) => user.status == 'Blocked').length;

  StreamSubscription<QuerySnapshot>? _usersSubscription;

  UserProvider() {
    initUsersStream();
  }

  void initUsersStream() {
    _isLoading = true;
    notifyListeners();

    try {
      _usersSubscription?.cancel();
      _usersSubscription = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _users = snapshot.docs
                  .map(
                    (doc) => UserModel.fromJson({...doc.data(), 'uid': doc.id}),
                  )
                  .toList();
              _applyFilters();
              _isLoading = false;
              _error = '';
              notifyListeners();
            },
            onError: (error) {
              _error = 'Failed to load users: $error';
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _error = 'Failed to initialize users stream: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          user.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _statusFilter == 'All' || user.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void searchUsers(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  Future<bool> updateUserStatus(String userId, String newStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      _error = 'Failed to update user status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Also delete related data (orders, wishlist, cart)
      await _deleteUserRelatedData(userId);

      return true;
    } catch (e) {
      _error = 'Failed to delete user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _deleteUserRelatedData(String userId) async {
    try {
      // Delete user's orders
      final ordersQuery = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in ordersQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's wishlist
      final wishlistQuery = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in wishlistQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's cart
      final cartQuery = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in cartQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Log error but don't fail the main operation
      debugPrint('Error deleting user related data: $e');
    }
  }

  Future<bool> bulkUpdateStatus(List<String> userIds, String newStatus) async {
    try {
      final batch = _firestore.batch();

      for (var userId in userIds) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'status': newStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      _error = 'Failed to bulk update user status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> bulkDeleteUsers(List<String> userIds) async {
    try {
      final batch = _firestore.batch();

      for (var userId in userIds) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.delete(userRef);

        // Also delete related data
        await _deleteUserRelatedData(userId);
      }

      await batch.commit();
      return true;
    } catch (e) {
      _error = 'Failed to bulk delete users: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }
}
