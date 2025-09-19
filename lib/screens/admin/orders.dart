import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_bite/screens/models/cart_model.dart';
import 'package:quick_bite/screens/models/order_model.dart';

class OrdersList extends StatelessWidget {
  static const routeName = '/ordersList';
  const OrdersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showDeleteAllConfirmation(context),
            tooltip: 'Delete All Orders',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh will happen automatically with StreamBuilder
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _OrdersSummary(),
            SizedBox(height: 16),
            Expanded(child: _OrdersList()),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(
                context,
                'All Orders',
                Icons.all_inclusive,
                null,
              ),
              _buildFilterOption(
                context,
                'Pending',
                Icons.pending_actions,
                OrderStatus.pending,
              ),
              _buildFilterOption(
                context,
                'Confirmed',
                Icons.check_circle_outline,
                OrderStatus.confirmed,
              ),
              _buildFilterOption(
                context,
                'Preparing',
                Icons.restaurant,
                OrderStatus.preparing,
              ),
              _buildFilterOption(
                context,
                'Out for Delivery',
                Icons.delivery_dining,
                OrderStatus.outForDelivery,
              ),
              _buildFilterOption(
                context,
                'Delivered',
                Icons.check_circle,
                OrderStatus.delivered,
              ),
              _buildFilterOption(
                context,
                'Cancelled',
                Icons.cancel,
                OrderStatus.cancelled,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String title,
    IconData icon,
    OrderStatus? status,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // TODO: Implement filter functionality
        Navigator.of(context).pop();
      },
    );
  }

  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          '⚠️ Delete All Orders',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'This action will permanently delete ALL orders from the database.',
              style: TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This cannot be undone. Are you absolutely sure?',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _confirmDeleteAll(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All Orders'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          '🔥 Final Confirmation',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Type "DELETE ALL" to confirm this destructive action:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close first dialog
              _performDeleteAll(context);
            },
            child: const Text(
              'I Understand - Delete Everything',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _performDeleteAll(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting all orders...'),
            ],
          ),
        ),
      );

      // Get all orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();

      // Delete all orders in batch
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in ordersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Close loading dialog and show success message
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All orders have been deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error message
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _OrdersSummary extends StatelessWidget {
  const _OrdersSummary();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Error loading summary')),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final orders = snapshot.data?.docs ?? [];
        final totalOrders = orders.length;

        // Calculate status counts
        int pending = 0,
            confirmed = 0,
            preparing = 0,
            outForDelivery = 0,
            delivered = 0,
            cancelled = 0;

        for (final doc in orders) {
          try {
            final order = OrderModel.fromDocument(doc);
            switch (order.status) {
              case OrderStatus.pending:
                pending++;
                break;
              case OrderStatus.confirmed:
                confirmed++;
                break;
              case OrderStatus.preparing:
                preparing++;
                break;
              case OrderStatus.outForDelivery:
                outForDelivery++;
                break;
              case OrderStatus.delivered:
                delivered++;
                break;
              case OrderStatus.cancelled:
                cancelled++;
                break;
              case OrderStatus.failed:
                cancelled++; // Treat failed as cancelled for summary
                break;
            }
          } catch (e) {
            // Skip invalid orders
            continue;
          }
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  count: totalOrders.toString(),
                  label: 'Total Orders',
                  icon: Icons.shopping_bag,
                  color: Colors.blue,
                ),
                _SummaryItem(
                  count: delivered.toString(),
                  label: 'Completed',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _SummaryItem(
                  count: (pending + confirmed + preparing + outForDelivery)
                      .toString(),
                  label: 'Active',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                _SummaryItem(
                  count: cancelled.toString(),
                  label: 'Cancelled',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _EmptyState();
        }

        return ListView.separated(
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            try {
              final order = OrderModel.fromDocument(doc);
              return _OrderCard(order: order, docId: doc.id);
            } catch (e) {
              // Handle invalid order data
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: const Text('Invalid Order Data'),
                  subtitle: Text('Document ID: ${doc.id}'),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String docId;

  const _OrderCard({required this.order, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status),
          child: Text(
            order.displayOrderId.replaceFirst('#', ''),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          order.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.userEmail,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'KES ${order.total.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(order.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (order.paymentInfo.phoneNumber != null)
              Text(
                '📱 ${order.paymentInfo.phoneNumber}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.statusDisplayName,
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._buildOrderItems(order.items),
                const SizedBox(height: 16),
                _buildOrderDetails(context),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: KES ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (order.status != OrderStatus.delivered &&
                            order.status != OrderStatus.cancelled)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _updateOrderStatus(context),
                            tooltip: 'Update Status',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => _deleteOrder(context),
                          tooltip: 'Delete Order',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.deliveryAddress.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.payment, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${order.paymentInfo.method.name.toUpperCase()} - ${order.paymentInfo.displayName}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.note, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildOrderItems(List<CartModel> items) {
    return items.map<Widget>((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${item.productName} x${item.quantity}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              'KES ${(item.productPrice * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.failed:
        return Colors.red;
    }
  }

  void _updateOrderStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Confirmed'),
              leading: const Icon(Icons.check_circle_outline),
              onTap: () => _changeStatus(context, OrderStatus.confirmed),
            ),
            ListTile(
              title: const Text('Preparing'),
              leading: const Icon(Icons.restaurant),
              onTap: () => _changeStatus(context, OrderStatus.preparing),
            ),
            ListTile(
              title: const Text('Out for Delivery'),
              leading: const Icon(Icons.delivery_dining),
              onTap: () => _changeStatus(context, OrderStatus.outForDelivery),
            ),
            ListTile(
              title: const Text('Delivered'),
              leading: const Icon(Icons.check_circle),
              onTap: () => _changeStatus(context, OrderStatus.delivered),
            ),
            ListTile(
              title: const Text('Cancelled'),
              leading: const Icon(Icons.cancel),
              onTap: () => _changeStatus(context, OrderStatus.cancelled),
            ),
          ],
        ),
      ),
    );
  }

  void _changeStatus(BuildContext context, OrderStatus newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to ${newStatus.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order status: $e')),
        );
      }
    }
  }

  void _deleteOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete order: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading orders...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Retry logic would go here
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Orders Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'All orders will appear here',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
