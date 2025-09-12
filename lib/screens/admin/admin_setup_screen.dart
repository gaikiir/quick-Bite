import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_bite/services/admin_manager.dart';

class AdminSetupScreen extends StatefulWidget {
  static const routeName = '/admin-setup';

  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  List<Map<String, dynamic>> _admins = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final admins = await AdminManager.getAllAdmins();
      setState(() {
        _admins = admins;
        _statusMessage = 'Loaded ${admins.length} admins';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error loading admins: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeFirstAdmin() async {
    setState(() => _isLoading = true);
    try {
      final success = await AdminManager.initializeFirstAdmin();
      if (success) {
        setState(
          () => _statusMessage =
              '🎉 First admin initialized successfully!\nYou now have full admin access.',
        );
        await _loadAdmins();

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Admin Setup Complete!'),
              content: const Text(
                'You are now the first admin user.\n\nYou can now:\n'
                '• Access all admin panels\n'
                '• Manage users, products, and orders\n'
                '• Add other admin users\n\n'
                'Restart the app to apply all permissions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(
          () => _statusMessage =
              '❌ Failed to initialize first admin. You might already be an admin.',
        );
      }
    } catch (e) {
      setState(() => _statusMessage = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? 'Not logged in'}'),
                    Text('UID: ${user?.uid ?? 'N/A'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Admin Setup Actions
            const Text(
              'Admin Setup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _initializeFirstAdmin,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Initialize First Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadAdmins,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Admin List'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _statusMessage.contains('Error') ||
                          _statusMessage.contains('Failed')
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color:
                        _statusMessage.contains('Error') ||
                            _statusMessage.contains('Failed')
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Admin List
            const Text(
              'Current Admins',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _admins.isEmpty
                  ? const Center(child: Text('No admins found'))
                  : ListView.builder(
                      itemCount: _admins.length,
                      itemBuilder: (context, index) {
                        final admin = _admins[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.red,
                            ),
                            title: Text(admin['email'] ?? 'No email'),
                            subtitle: Text('Role: ${admin['role'] ?? 'admin'}'),
                            trailing: admin['isFirstAdmin'] == true
                                ? Chip(
                                    label: const Text('Super Admin'),
                                    backgroundColor: Colors.red.shade100,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
