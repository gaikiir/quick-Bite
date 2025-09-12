import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if the current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();
      return adminDoc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Add a user as admin (only existing admins can do this)
  static Future<bool> addAdmin(
    String userId, {
    String? email,
    String? role = 'admin',
  }) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        print('Only admins can add other admins');
        return false;
      }

      // Add user to admins collection
      await _firestore.collection('admins').doc(userId).set({
        'userId': userId,
        'email': email,
        'role': role,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': _auth.currentUser?.uid,
      });

      print('Successfully added admin: $userId');
      return true;
    } catch (e) {
      print('Error adding admin: $e');
      return false;
    }
  }

  /// Remove admin privileges from a user
  static Future<bool> removeAdmin(String userId) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        print('Only admins can remove admin privileges');
        return false;
      }

      await _firestore.collection('admins').doc(userId).delete();
      print('Successfully removed admin: $userId');
      return true;
    } catch (e) {
      print('Error removing admin: $e');
      return false;
    }
  }

  /// Get all admins
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        print('Only admins can view admin list');
        return [];
      }

      final snapshot = await _firestore.collection('admins').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting admins: $e');
      return [];
    }
  }

  /// Initialize first admin (use this only once to create the first admin)
  static Future<bool> initializeFirstAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return false;
      }

      // Check if any admins exist
      final adminSnapshot = await _firestore
          .collection('admins')
          .limit(1)
          .get();
      if (adminSnapshot.docs.isNotEmpty) {
        print('Admins already exist. Use addAdmin() instead.');
        return false;
      }

      // Create first admin
      await _firestore.collection('admins').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'role': 'super_admin',
        'addedAt': FieldValue.serverTimestamp(),
        'isFirstAdmin': true,
      });

      print('Successfully created first admin: ${user.email}');
      return true;
    } catch (e) {
      print('Error initializing first admin: $e');
      return false;
    }
  }
}
