import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromJson(data);
      }).toList();
    });
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Update user status (block/unblock)
  Future<void> updateUserStatus(String uid, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': isBlocked ? 'Blocked' : 'Active',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
}
