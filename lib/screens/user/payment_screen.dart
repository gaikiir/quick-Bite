import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/models/order_model.dart';
import 'package:quick_bite/screens/provider/cart_provider.dart';
import 'package:quick_bite/screens/provider/order_provider.dart';
import 'package:quick_bite/screens/services/mpesa_service.dart';
import 'package:quick_bite/screens/user/order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  static const routeName = '/payment';

  final OrderModel order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessingPayment = false;
  bool _paymentInitiated = false;
  String? _checkoutRequestId;
  String? _errorMessage;
  Timer? _statusTimer;
  int _timeoutSeconds = 120; // 2 minutes timeout
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Auto-initiate payment for M-Pesa
    if (widget.order.paymentInfo.method == PaymentMethod.mpesa) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initiateMpesaPayment();
      });
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        automaticallyImplyLeading: !_isProcessingPayment,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfo(theme),
            const SizedBox(height: 24),
            _buildPaymentMethod(theme),
            const SizedBox(height: 24),
            Expanded(child: _buildPaymentStatus(theme)),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Order ID',
              widget.order.orderId.substring(0, 8).toUpperCase(),
              theme,
            ),
            _buildDetailRow(
              'Total Amount',
              'KES ${widget.order.totalAmount.toStringAsFixed(2)}',
              theme,
            ),
            _buildDetailRow(
              'Items',
              '${widget.order.items.length} item(s)',
              theme,
            ),
            _buildDetailRow(
              'Delivery to',
              widget.order.deliveryAddress.toString(),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(ThemeData theme) {
    final method = widget.order.paymentInfo.method;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getPaymentMethodIcon(method),
                color: theme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPaymentMethodName(method),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPaymentMethodDescription(method),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildPaymentStatus(ThemeData theme) {
    if (widget.order.paymentInfo.method == PaymentMethod.cash) {
      return _buildCashPaymentStatus(theme);
    } else if (widget.order.paymentInfo.method == PaymentMethod.mpesa) {
      return _buildMpesaPaymentStatus(theme);
    } else {
      return _buildCardPaymentStatus(theme);
    }
  }

  Widget _buildCashPaymentStatus(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Order Confirmed!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your order has been confirmed. You will pay cash when your order is delivered.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount to Pay on Delivery',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${widget.order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
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

  Widget _buildMpesaPaymentStatus(ThemeData theme) {
    if (_errorMessage != null) {
      return _buildPaymentError(theme);
    }

    if (!_paymentInitiated) {
      return _buildPaymentInitiating(theme);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, size: 80, color: theme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'M-Pesa Payment Request Sent',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A payment request has been sent to your phone. Please check your M-Pesa messages and enter your PIN to complete the payment.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount to Pay',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${widget.order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isProcessingPayment) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Waiting for payment confirmation...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Timeout in $_timeoutSeconds seconds',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardPaymentStatus(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Card Payment',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Card payment integration coming soon. Please select M-Pesa or Cash on Delivery for now.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInitiating(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Initiating Payment...',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we prepare your M-Pesa payment request.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentError(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Payment Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ??
                  'An error occurred while processing your payment.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryPayment,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (widget.order.paymentInfo.method == PaymentMethod.cash ||
        widget.order.paymentInfo.status == PaymentStatus.completed) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _navigateToSuccess(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _retryPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isProcessingPayment ? null : () => _cancelPayment(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cancel Payment',
          style: TextStyle(
            color: _isProcessingPayment ? null : Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _initiateMpesaPayment() async {
    if (!MpesaService.validateConfig()) {
      setState(() {
        _errorMessage =
            'M-Pesa configuration not set up. Please contact support.';
      });
      return;
    }

    setState(() {
      _isProcessingPayment = true;
      _paymentInitiated = false;
      _errorMessage = null;
    });

    try {
      final response = await MpesaService.initiateSTKPush(
        phoneNumber: widget.order.userPhone,
        amount: widget.order.totalAmount,
        accountReference: widget.order.orderId.substring(0, 8).toUpperCase(),
        transactionDesc: 'Quick Bite Order Payment',
      );

      if (response.success && response.checkoutRequestId != null) {
        setState(() {
          _checkoutRequestId = response.checkoutRequestId;
          _paymentInitiated = true;
        });

        // Start monitoring payment status
        _startPaymentStatusMonitoring();
        _startTimeoutTimer();
      } else {
        setState(() {
          _errorMessage = response.errorMessage ?? 'Failed to initiate payment';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initiate payment: $e';
      });
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  void _startPaymentStatusMonitoring() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_checkoutRequestId == null) return;

      try {
        // In a real implementation, you would query the payment status
        // For now, we'll simulate the payment callback
        final status = await MpesaService.simulatePaymentCallback(
          checkoutRequestId: _checkoutRequestId!,
          success: true, // Simulate success for demo
          amount: widget.order.totalAmount,
        );

        if (status.isSuccess) {
          _handlePaymentSuccess(status);
        } else if (status.isCancelled) {
          _handlePaymentCancellation();
        }
      } catch (e) {
        debugPrint('Error checking payment status: $e');
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeoutSeconds--;
      });

      if (_timeoutSeconds <= 0) {
        _handlePaymentTimeout();
      }
    });
  }

  void _handlePaymentSuccess(MpesaPaymentStatus status) async {
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();

    // Update payment info
    final updatedPaymentInfo = PaymentInfo(
      method: PaymentMethod.mpesa,
      status: PaymentStatus.completed,
      transactionId: _checkoutRequestId,
      mpesaReference: status.mpesaReceiptNumber,
      phoneNumber: status.phoneNumber,
      paidAt: DateTime.now(),
    );

    // Update order in provider
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.updatePaymentInfo(
      widget.order.orderId,
      updatedPaymentInfo,
    );
    await orderProvider.updateOrderStatus(
      widget.order.orderId,
      OrderStatus.confirmed,
    );

    // Clear cart
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();

    // Navigate to success screen
    _navigateToSuccess();
  }

  void _handlePaymentCancellation() {
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();

    setState(() {
      _errorMessage = 'Payment was cancelled by user';
      _isProcessingPayment = false;
    });
  }

  void _handlePaymentTimeout() {
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();

    setState(() {
      _errorMessage = 'Payment request timed out. Please try again.';
      _isProcessingPayment = false;
    });
  }

  void _retryPayment() {
    setState(() {
      _errorMessage = null;
      _timeoutSeconds = 120;
    });
    _initiateMpesaPayment();
  }

  void _cancelPayment() async {
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();

    // Cancel the order
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.cancelOrder(
      widget.order.orderId,
      reason: 'Payment cancelled by user',
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _navigateToSuccess() {
    Navigator.pushReplacementNamed(
      context,
      OrderSuccessScreen.routeName,
      arguments: widget.order,
    );
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

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'Secure mobile payment';
      case PaymentMethod.cash:
        return 'Pay when delivered';
      case PaymentMethod.card:
        return 'Pay with card';
    }
  }
}
