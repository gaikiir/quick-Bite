import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mpesa_service.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import '../provider/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  // Constants
  static const double _deliveryFee = 100.0;
  static const double _freeDeliveryThreshold = 1500.0;

  @override
  void dispose() {
    _streetController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.cartItems.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOrderSummary(cartProvider),
                        const SizedBox(height: 24),
                        _buildDeliverySection(),
                        const SizedBox(height: 24),
                        _buildPaymentSection(),
                        const SizedBox(height: 24),
                        _buildOrderTotal(cartProvider),
                      ],
                    ),
                  ),
                ),
              ),
              _buildCheckoutButton(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...cartProvider.cartItems.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.productImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            'KES ${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'Enter your delivery address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your delivery address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.trim().length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Delivery Notes (Optional)',
                hintText: 'Any special instructions...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              PaymentMethod.cash,
              'Cash on Delivery',
              'Pay with cash when order arrives',
              Icons.money,
              Colors.green,
            ),
            _buildPaymentOption(
              PaymentMethod.card,
              'Credit/Debit Card',
              'Pay securely with your card',
              Icons.credit_card,
              Colors.blue,
            ),
            _buildPaymentOption(
              PaymentMethod.mpesa,
              'M-Pesa',
              'Pay instantly with M-Pesa',
              Icons.phone_android,
              Colors.green[700]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == method
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Transform.scale(
          scale: 1.2,
          child: Radio<PaymentMethod>.adaptive(
            value: method,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              }
            },
          ),
        ),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
      ),
    );
  }

  Widget _buildOrderTotal(CartProvider cartProvider) {
    final subtotal = cartProvider.totalAmount;
    final deliveryFee = _calculateDeliveryFee(subtotal);
    final total = subtotal + deliveryFee;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', 'KES ${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Delivery Fee',
              deliveryFee == 0
                  ? 'FREE'
                  : 'KES ${deliveryFee.toStringAsFixed(2)}',
            ),
            if (deliveryFee == 0 && subtotal >= _freeDeliveryThreshold)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Free delivery on orders above KES ${_freeDeliveryThreshold.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.green[600], fontSize: 12),
                ),
              ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total',
              'KES ${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? Theme.of(context).primaryColor : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(CartProvider cartProvider) {
    final total =
        cartProvider.totalAmount +
        _calculateDeliveryFee(cartProvider.totalAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _handleCheckout(cartProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Place Order - KES ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  double _calculateDeliveryFee(double subtotal) {
    return subtotal >= _freeDeliveryThreshold ? 0.0 : _deliveryFee;
  }

  Future<void> _handleCheckout(CartProvider cartProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_selectedPaymentMethod == PaymentMethod.mpesa) {
        await _handleMpesaPayment(cartProvider);
      } else {
        await _handleRegularPayment(cartProvider);
      }
    } catch (e) {
      _showErrorMessage('Failed to place order: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleMpesaPayment(CartProvider cartProvider) async {
    final total =
        cartProvider.totalAmount +
        _calculateDeliveryFee(cartProvider.totalAmount);
    final phoneNumber = _phoneController.text.trim();

    // Validate phone number for M-Pesa
    try {
      MpesaService.formatPhoneNumber(phoneNumber);
    } catch (e) {
      _showErrorMessage(
        'Please enter a valid M-Pesa phone number (254XXXXXXXXX)',
      );
      return;
    }

    // Show loading indicator
    _showInfoMessage('Initiating M-Pesa payment... Please check your phone.');

    try {
      final response = await MpesaService.initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: total,
        accountReference: 'QB${DateTime.now().millisecondsSinceEpoch}',
        transactionDesc: 'QuickBite Order Payment',
      );

      if (response.success && mounted) {
        _showSuccessMessage(
          'M-Pesa payment initiated! Check your phone to complete payment.',
        );
        await _createOrder(
          cartProvider,
          PaymentStatus.pending,
          'M-Pesa payment initiated',
        );
      } else {
        _showErrorMessage(response.errorMessage ?? 'M-Pesa payment failed');
      }
    } catch (e) {
      _showErrorMessage('M-Pesa payment error: $e');
    }
  }

  Future<void> _handleRegularPayment(CartProvider cartProvider) async {
    final paymentStatus = _selectedPaymentMethod == PaymentMethod.cash
        ? PaymentStatus.pending
        : PaymentStatus.processing;

    await _createOrder(
      cartProvider,
      paymentStatus,
      'Order placed successfully',
    );
    if (mounted) {
      _showSuccessMessage('Order placed successfully!');
      Navigator.pushReplacementNamed(context, '/order-success');
    }
  }

  Future<void> _createOrder(
    CartProvider cartProvider,
    PaymentStatus paymentStatus,
    String paymentNote,
  ) async {
    // Create order logic here - implement with OrderProvider when ready
    await cartProvider.clearCart();

    // For now, just log the order details
    debugPrint('Order created:');
    debugPrint('Payment Method: $_selectedPaymentMethod');
    debugPrint('Payment Status: $paymentStatus');
    debugPrint('Payment Note: $paymentNote');
    debugPrint('Address: ${_streetController.text}');
    debugPrint('Phone: ${_phoneController.text}');
    debugPrint('Notes: ${_notesController.text}');
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
