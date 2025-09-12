import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_bite/screens/admin/add_product_screen.dart';
import 'package:quick_bite/screens/admin/category_management_screen.dart';
import 'package:quick_bite/screens/admin/orders.dart';
import 'package:quick_bite/screens/admin/users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await Future.wait([
        _getUsersCount(),
        _getProductsCount(),
        _getCategoriesCount(),
        _getOrdersCount(),
        _getTotalRevenue(),
      ]);

      setState(() {
        _stats = {
          'users': stats[0],
          'products': stats[1],
          'categories': stats[2],
          'orders': stats[3],
          'revenue': stats[4],
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getUsersCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> _getProductsCount() async {
    final snapshot = await _firestore.collection('products').get();
    return snapshot.docs.length;
  }

  Future<int> _getCategoriesCount() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.length;
  }

  Future<int> _getOrdersCount() async {
    final snapshot = await _firestore.collection('orders').get();
    return snapshot.docs.length;
  }

  Future<double> _getTotalRevenue() async {
    final snapshot = await _firestore.collection('orders').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['totalAmount'] != null) {
        total += (data['totalAmount'] as num).toDouble();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeCard(user, theme),
                    const SizedBox(height: 24),

                    // Statistics Grid
                    _buildStatsGrid(theme),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(User? user, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, Admin!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'admin@quickbite.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final stats = [
      {
        'title': 'Total Users',
        'value': _stats['users']?.toString() ?? '0',
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Products',
        'value': _stats['products']?.toString() ?? '0',
        'icon': Icons.inventory,
        'color': Colors.green,
      },
      {
        'title': 'Categories',
        'value': _stats['categories']?.toString() ?? '0',
        'icon': Icons.category,
        'color': Colors.orange,
      },
      {
        'title': 'Orders',
        'value': _stats['orders']?.toString() ?? '0',
        'icon': Icons.shopping_cart,
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: stats.map((stat) => _buildStatCard(stat, theme)).toList(),
        ),
        const SizedBox(height: 16),
        _buildRevenueCard(theme),
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(stat['icon'], size: 32, color: stat['color']),
            const SizedBox(height: 8),
            Text(
              stat['value'],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: stat['color'],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat['title'],
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.attach_money,
                size: 24,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Revenue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_stats['revenue']?.toStringAsFixed(2) ?? '0.00'}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final actions = [
      {
        'title': 'Add Product',
        'icon': Icons.add_box,
        'color': Colors.blue,
        'route': AddProductScreen.routeName,
      },
      {
        'title': 'Categories',
        'icon': Icons.category,
        'color': Colors.orange,
        'route': CategoryManagementScreen.routeName,
      },
      {
        'title': 'Users',
        'icon': Icons.people,
        'color': Colors.green,
        'route': UsersScreen.routeName,
      },
      {
        'title': 'Orders',
        'icon': Icons.shopping_cart,
        'color': Colors.purple,
        'route': OrdersList.routeName,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: actions
              .map((action) => _buildActionCard(action, theme))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, action['route']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action['icon'], size: 32, color: action['color']),
              const SizedBox(height: 8),
              Text(
                action['title'],
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
