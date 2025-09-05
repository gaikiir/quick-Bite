import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class UsersScreen extends StatefulWidget {
  static const routeName = '/usersScreen';
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _error = '';
  StreamSubscription? _usersSubscription;

  @override
  void initState() {
    super.initState();
    _initUsersStream();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  void _initUsersStream() {
    _usersSubscription = _userService.getAllUsers().listen(
      (users) {
        if (mounted) {
          setState(() {
            _users = users;
            _isLoading = false;
            _error = '';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load users: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<bool?> _showConfirmationDialog(String action, String userName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action User'),
        content: Text('Are you sure you want to $action "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: action == 'Delete' ? Colors.red : Colors.orange,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _deleteUser(String userId) async {
    final user = _users.firstWhere((user) => user.uid == userId);
    final shouldDelete = await _showConfirmationDialog('Delete', user.userName);

    if (shouldDelete == true) {
      try {
        await _userService.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.userName} has been deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
      }
    }
  }

  void _toggleUserBlock(String userId) async {
    final user = _users.firstWhere((user) => user.uid == userId);
    final isBlocked = user.status == 'Blocked';
    final action = isBlocked ? 'Unblock' : 'Block';

    final shouldToggle = await _showConfirmationDialog(action, user.userName);

    if (shouldToggle == true) {
      try {
        await _userService.updateUserStatus(userId, !isBlocked);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.userName} has been ${isBlocked ? 'unblocked' : 'blocked'}',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initUsersStream,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'All Users',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_users.length} users',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    elevation: 3,
                    child: InkWell(
                      onTap: () {
                        // Show user details if needed
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  radius: 30,
                                  child: user.profileImage.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            user.profileImage,
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                          ),
                                        )
                                      : Text(
                                          user.userName[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                if (user.status == 'Blocked')
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.lock,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user.status == 'Active'
                                        ? Colors.green[100]
                                        : user.status == 'Blocked'
                                        ? Colors.orange[100]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.status,
                                    style: TextStyle(
                                      color: user.status == 'Active'
                                          ? Colors.green[800]
                                          : user.status == 'Blocked'
                                          ? Colors.orange[800]
                                          : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${user.orderCount} orders',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () => _toggleUserBlock(user.uid),
                                  icon: Icon(
                                    user.status == 'Blocked'
                                        ? Icons.lock_open
                                        : Icons.lock_person,
                                    color: user.status == 'Blocked'
                                        ? Colors.orange
                                        : Colors.grey[600],
                                  ),
                                  tooltip: user.status == 'Blocked'
                                      ? 'Unblock User'
                                      : 'Block User',
                                ),
                                IconButton(
                                  onPressed: () => _deleteUser(user.uid),
                                  icon: const Icon(Icons.delete_forever),
                                  color: Colors.red,
                                  tooltip: 'Delete User',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
