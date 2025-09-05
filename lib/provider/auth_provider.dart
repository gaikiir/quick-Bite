import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum UserRole { admin, user, none }

class QuickBiteAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  UserRole _userRole = UserRole.none;
  bool _isLoading = true;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      _isLoading = true;
      notifyListeners();

      if (user != null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final role = userDoc.data()?['role'] as String?;
            _userRole = role == 'admin' ? UserRole.admin : UserRole.user;
          } else {
            _userRole = UserRole.user;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching user role: $e');
          }
          _userRole = UserRole.user;
        }
      } else {
        _userRole = UserRole.none;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  UserRole get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _userRole == UserRole.admin;

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
