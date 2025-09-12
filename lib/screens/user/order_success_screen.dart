import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/models/order_model.dart';
import 'package:quick_bite/screens/provider/order_provider.dart';
import 'package:quick_bite/screens/user/user_root.dart';

class OrderSuccessScreen extends StatelessWidget {
  static const routeName = '/order-success';

  final OrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildSuccessIcon(theme),
                      const SizedBox(height: 24),
                      _buildSuccessMessage(theme),
                      const SizedBox(height: 32),
                      _buildOrderSummary(theme),
                      const SizedBox(height: 24),
                      _buildDeliveryInfo(theme),
                      const SizedBox(height: 24),
                      _buildPaymentInfo(theme),
                      const SizedBox(height: 24),
                      _buildNextSteps(theme),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
    );
  }

  Widget _buildSuccessMessage(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Order Placed Successfully!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Thank you for choosing Quick Bite. Your order has been confirmed and will be prepared soon.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Order ID',
              order.orderId.substring(0, 8).toUpperCase(),
              theme,
            ),
            _buildInfoRow(
              'Order Date',
              _formatDateTime(order.createdAt),
              theme,
            ),
            _buildInfoRow('Status', order.statusDisplayName, theme),
            _buildInfoRow('Items', '${order.items.length} item(s)', theme),
            const Divider(height: 24),
            _buildInfoRow(
              'Subtotal',
              'KES ${order.subtotal.toStringAsFixed(2)}',
              theme,
            ),
            _buildInfoRow(
              'Delivery Fee',
              'KES ${order.deliveryFee.toStringAsFixed(2)}',
              theme,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Total Amount',
              'KES ${order.totalAmount.toStringAsFixed(2)}',
              theme,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Delivery Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Delivery to', order.userName, theme),
            _buildInfoRow('Phone', order.userPhone, theme),
            const SizedBox(height: 8),
            Text(
              'Address:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress.toString(),
              style: theme.textTheme.bodyMedium,
            ),
            if (order.deliveryAddress.deliveryInstructions != null) ...[
              const SizedBox(height: 8),
              Text(
                'Special Instructions:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.deliveryAddress.deliveryInstructions!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPaymentMethodIcon(order.paymentInfo.method),
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Payment Method',
              _getPaymentMethodName(order.paymentInfo.method),
              theme,
            ),
            _buildInfoRow(
              'Payment Status',
              order.paymentStatusDisplayName,
              theme,
            ),
            if (order.paymentInfo.mpesaReference != null)
              _buildInfoRow(
                'M-Pesa Reference',
                order.paymentInfo.mpesaReference!,
                theme,
              ),
            if (order.paymentInfo.transactionId != null)
              _buildInfoRow(
                'Transaction ID',
                order.paymentInfo.transactionId!.substring(0, 8).toUpperCase(),
                theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSteps(ThemeData theme) {
    final steps = [
      'Your order is being prepared',
      'You will receive updates via SMS',
      'Our delivery team will contact you',
      'Enjoy your meal!',
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: theme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'What\'s Next?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isFirst = index == 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isFirst
                            ? theme.primaryColor
                            : theme.colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isFirst
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isFirst
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: isFirst
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
          ),
          Expanded(
            child: Text(
              value,
              style: isTotal
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _trackOrder(context),
            icon: const Icon(Icons.track_changes),
            label: const Text(
              'Track Your Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _continueShopping(context),
            icon: const Icon(Icons.shopping_bag),
            label: const Text(
              'Continue Shopping',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _trackOrder(BuildContext context) {
    // Initialize orders stream to ensure order is loaded
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.initOrdersStream();

    // Navigate to orders/tracking screen
    // For now, go back to home and show a message
    Navigator.pushNamedAndRemoveUntil(
      context,
      UserRoot.routeName,
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order ${order.orderId.substring(0, 8).toUpperCase()} is being tracked',
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _continueShopping(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      UserRoot.routeName,
      (route) => false,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return Icons.phone_android;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.cash:
        return 'Cash on Delivery';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
    }
  }
}
