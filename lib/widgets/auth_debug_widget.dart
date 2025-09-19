import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthDebugWidget extends StatelessWidget {
  const AuthDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user != null ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: user != null ? Colors.green : Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user != null ? '✅ Authenticated' : '❌ Not Authenticated',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: user != null ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 8),
            Text('User ID: ${user.uid}'),
            Text('Email: ${user.email ?? 'No email'}'),
            Text('Display Name: ${user.displayName ?? 'No name'}'),
          ] else ...[
            const SizedBox(height: 8),
            const Text('Please sign in to perform database operations'),
          ],
        ],
      ),
    );
  }
}

// Utility function to check auth status
Future<void> checkAuthStatus() async {
  final user = FirebaseAuth.instance.currentUser;
  debugPrint('=== AUTH STATUS CHECK ===');
  debugPrint('User authenticated: ${user != null}');
  if (user != null) {
    debugPrint('User ID: ${user.uid}');
    debugPrint('User Email: ${user.email}');
    debugPrint('User Display Name: ${user.displayName}');
  } else {
    debugPrint('No user is currently signed in');
  }
  debugPrint('========================');
}
