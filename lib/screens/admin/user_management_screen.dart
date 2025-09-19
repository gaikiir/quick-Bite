import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../provider/user_provider.dart';
import '../widgets/user_shimmer.dart';

class UserManagementScreen extends StatefulWidget {
  static const routeName = '/userManagement';
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String searchQuery = '';
  String statusFilter = 'All';
  bool showGridView = false;
  Set<String> selectedUsers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(showGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => showGridView = !showGridView),
            tooltip: showGridView
                ? 'Switch to List View'
                : 'Switch to Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UserProvider>().initUsersStream(),
            tooltip: 'Refresh Users',
          ),
        ],
        bottom: selectedUsers.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: _buildBulkActions(),
              )
            : null,
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Statistics Cards
              _buildStatisticsCards(provider),

              // Search and Filter Section
              _buildSearchAndFilterSection(provider),

              // Users Display
              Expanded(child: _buildUsersDisplay(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards(UserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildStatCard(
            title: 'Total Users',
            value: provider.totalUsers.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
          _buildStatCard(
            title: 'Active',
            value: provider.activeUsers.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatCard(
            title: 'Suspended',
            value: provider.suspendedUsers.toString(),
            icon: Icons.pause_circle,
            color: Colors.orange,
          ),
          _buildStatCard(
            title: 'Blocked',
            value: provider.blockedUsers.toString(),
            icon: Icons.block,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(UserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (query) {
              setState(() => searchQuery = query);
              provider.searchUsers(query);
            },
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => searchQuery = '');
                        provider.searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Filters Row
          Row(
            children: [
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                    DropdownMenuItem(
                      value: 'Active',
                      child: Text('Active Only'),
                    ),
                    DropdownMenuItem(
                      value: 'Suspended',
                      child: Text('Suspended Only'),
                    ),
                    DropdownMenuItem(
                      value: 'Blocked',
                      child: Text('Blocked Only'),
                    ),
                  ],
                  onChanged: (status) {
                    if (status != null) {
                      setState(() => statusFilter = status);
                      provider.filterByStatus(status);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Select All Checkbox
              Checkbox(
                value:
                    selectedUsers.length == provider.users.length &&
                    provider.users.isNotEmpty,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedUsers = provider.users
                          .map((user) => user.uid)
                          .toSet();
                    } else {
                      selectedUsers.clear();
                    }
                  });
                },
              ),
              const Text('Select All'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${selectedUsers.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _bulkUpdateStatus('Suspended'),
            icon: const Icon(Icons.pause, color: Colors.orange),
            label: const Text(
              'Suspend',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          TextButton.icon(
            onPressed: () => _bulkUpdateStatus('Blocked'),
            icon: const Icon(Icons.block, color: Colors.red),
            label: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
          TextButton.icon(
            onPressed: () => _bulkUpdateStatus('Active'),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text(
              'Activate',
              style: TextStyle(color: Colors.green),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _bulkDeleteUsers,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersDisplay(UserProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingView();
    }

    if (provider.error.isNotEmpty) {
      return _buildErrorView(provider);
    }

    if (provider.users.isEmpty) {
      return _buildEmptyView();
    }

    return showGridView ? _buildGridView(provider) : _buildListView(provider);
  }

  Widget _buildLoadingView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const UserShimmer(),
    );
  }

  Widget _buildErrorView(UserProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load users',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            provider.error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.initUsersStream(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Users will appear here once they register',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(UserProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.users.length,
      itemBuilder: (context, index) {
        final user = provider.users[index];
        return _buildUserGridCard(user, provider);
      },
    );
  }

  Widget _buildListView(UserProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.users.length,
      itemBuilder: (context, index) {
        final user = provider.users[index];
        return _buildUserListCard(user, provider);
      },
    );
  }

  Widget _buildUserGridCard(UserModel user, UserProvider provider) {
    final isSelected = selectedUsers.contains(user.uid);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleUserSelection(user.uid),
        onLongPress: () => _toggleUserSelection(user.uid),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image: DecorationImage(
                        image: user.profileImage.isNotEmpty
                            ? NetworkImage(user.profileImage)
                            : const AssetImage(
                                    'assets/images/default_profile.png',
                                  )
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        color: _getStatusColor(
                          user.status,
                        ).withValues(alpha: 0.8),
                      ),
                      child: Center(
                        child: Text(
                          user.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // User Details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              user.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${user.orderCount} orders',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(user.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),

            // Action buttons overlay
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showUserActions(user, provider),
                      color: Colors.blue,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListCard(UserModel user, UserProvider provider) {
    final isSelected = selectedUsers.contains(user.uid);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleUserSelection(user.uid),
        onLongPress: () => _toggleUserSelection(user.uid),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleUserSelection(user.uid),
              ),

              // Profile Image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: DecorationImage(
                    image: user.profileImage.isNotEmpty
                        ? NetworkImage(user.profileImage)
                        : const AssetImage('assets/images/default_profile.png')
                              as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              user.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(user.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${user.orderCount} orders',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(user.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showUserActions(user, provider),
                    tooltip: 'User Actions',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (selectedUsers.contains(userId)) {
        selectedUsers.remove(userId);
      } else {
        selectedUsers.add(userId);
      }
    });
  }

  void _showUserActions(UserModel user, UserProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user.profileImage.isNotEmpty
                      ? NetworkImage(user.profileImage)
                      : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'User Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.check_circle,
              label: 'Activate User',
              color: Colors.green,
              onTap: () => _updateUserStatus(user, 'Active', provider),
            ),
            _buildActionButton(
              icon: Icons.pause_circle,
              label: 'Suspend User',
              color: Colors.orange,
              onTap: () => _updateUserStatus(user, 'Suspended', provider),
            ),
            _buildActionButton(
              icon: Icons.block,
              label: 'Block User',
              color: Colors.red,
              onTap: () => _updateUserStatus(user, 'Blocked', provider),
            ),
            const Divider(),
            _buildActionButton(
              icon: Icons.delete_forever,
              label: 'Delete User',
              color: Colors.red,
              onTap: () => _deleteUser(user, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserStatus(
    UserModel user,
    String newStatus,
    UserProvider provider,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update User Status'),
        content: Text(
          'Are you sure you want to ${newStatus.toLowerCase()} ${user.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              newStatus,
              style: TextStyle(color: _getStatusColor(newStatus)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      final provider = context.read<UserProvider>();
      final success = await provider.updateUserStatus(user.uid, newStatus);
      if (success && context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.userName} has been ${newStatus.toLowerCase()}',
            ),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user, UserProvider provider) async {
    Navigator.pop(context); // Close bottom sheet

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete ${user.userName}? '
          'This will also delete all their orders, wishlist, and cart data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteUser(user.uid);
      if (success && context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User has been permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkUpdateStatus(String newStatus) async {
    if (selectedUsers.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Update Status'),
        content: Text(
          'Are you sure you want to ${newStatus.toLowerCase()} ${selectedUsers.length} selected users?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              newStatus,
              style: TextStyle(color: _getStatusColor(newStatus)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      final provider = context.read<UserProvider>();
      final success = await provider.bulkUpdateStatus(
        selectedUsers.toList(),
        newStatus,
      );

      if (success && context.mounted) {
        setState(() => selectedUsers.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedUsers.length} users have been ${newStatus.toLowerCase()}',
            ),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
      }
    }
  }

  Future<void> _bulkDeleteUsers() async {
    if (selectedUsers.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete Users'),
        content: Text(
          'Are you sure you want to permanently delete ${selectedUsers.length} selected users? '
          'This will also delete all their orders, wishlist, and cart data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      final provider = context.read<UserProvider>();
      final success = await provider.bulkDeleteUsers(selectedUsers.toList());

      if (success && context.mounted) {
        setState(() => selectedUsers.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected users have been permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Suspended':
        return Colors.orange;
      case 'Blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}
