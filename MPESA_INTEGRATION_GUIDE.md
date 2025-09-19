# M-Pesa Integration Guide for QuickBite

## Overview

This guide explains how to implement and use the M-Pesa payment integration in your QuickBite Flutter app. The integration supports both sandbox (testing) and production environments.

## 🚀 Quick Setup

### 1. Configuration

The M-Pesa configuration is already set up in `lib/config/mpesa_config.dart`:

```dart
// Configuration is ready with sandbox credentials
// Switch to production by updating the credentials and setting sandbox to false
```

### 2. Dependencies

The required `http` package is already included in `pubspec.yaml`.

### 3. Implementation Files

- **Config**: `lib/config/mpesa_config.dart` - Credentials and endpoints
- **Service**: `lib/services/mpesa_service.dart` - API communication
- **UI**: `lib/screens/mpesa_payment_screen.dart` - Payment interface
- **Integration**: `lib/screens/checkout_screen.dart` - Example checkout flow

## 📱 How to Use

### Basic Payment Flow

1. **Import the service**:

```dart
import '../services/mpesa_service.dart';
```

2. **Initiate STK Push**:

```dart
final response = await MpesaService.initiateSTKPush(
  phoneNumber: '0722123456',
  amount: 100.0,
  accountReference: 'ORDER123',
  transactionDesc: 'QuickBite Order Payment',
);

if (response.success) {
  print('Payment initiated: ${response.customerMessage}');
} else {
  print('Payment failed: ${response.errorMessage}');
}
```

3. **Use Payment Screen**:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MpesaPaymentScreen(
      amount: 500.0,
      accountReference: 'QB${DateTime.now().millisecondsSinceEpoch}',
      transactionDesc: 'Food Order Payment',
      onPaymentComplete: (response) {
        if (response.success) {
          // Handle successful payment
        } else {
          // Handle failed payment
        }
      },
    ),
  ),
);
```

## 🔧 Configuration Options

### Testing Mode

By default, mock mode is enabled for testing:

```dart
// In mpesa_config.dart
static const bool enableMockMode = true; // Set to false for production
```

### Production Setup

To switch to production:

1. Update credentials in `mpesa_config.dart`:

   - Set your production consumer key and secret
   - Update business short code
   - Set sandbox to `false`
   - Update callback URL to your server

2. Disable mock mode:
   ```dart
   static const bool enableMockMode = false;
   ```

## 📋 Payment Methods Integration

The `PaymentMethod` enum now includes M-Pesa:

```dart
enum PaymentMethod {
  cash,
  card,
  mpesa, // ✅ M-Pesa added
}
```

## 🎯 Example Integration

See `lib/screens/checkout_screen.dart` for a complete example of:

- Payment method selection
- M-Pesa payment flow
- Order creation after successful payment
- Error handling

## 📞 Phone Number Formats

The service automatically handles various phone number formats:

- `0722123456` → `254722123456`
- `722123456` → `254722123456`
- `254722123456` → `254722123456` (no change)

## ⚠️ Important Notes

### Security

- Never expose API credentials in client-side code for production
- Implement server-side validation for production payments
- Use callback URLs to verify payment status

### Testing

- Use sandbox credentials for testing
- Mock mode simulates successful payments without API calls
- Test with various phone number formats

### Error Handling

- Always check `response.success` before proceeding
- Display user-friendly error messages
- Implement retry mechanisms for network failures

## 🔄 Payment Flow

1. **User Selection**: User selects M-Pesa as payment method
2. **Payment Screen**: Navigate to M-Pesa payment screen
3. **Phone Input**: User enters M-Pesa phone number
4. **STK Push**: Service sends STK push request
5. **User Confirmation**: User enters PIN on their phone
6. **Response**: Service receives payment response
7. **Order Creation**: Create order on successful payment

## 🛠️ Customization

### UI Customization

- Modify `MpesaPaymentScreen` colors and styling
- Add your app branding
- Customize validation messages

### Service Extension

- Add transaction status checking
- Implement webhook handling
- Add retry logic for failed requests

## 📚 Next Steps

1. **Server Integration**: Implement callback handling on your server
2. **Status Verification**: Add transaction status checking
3. **Error Monitoring**: Implement comprehensive error tracking
4. **User Experience**: Add payment history and receipts

## 🔐 Production Checklist

- [ ] Update to production credentials
- [ ] Disable mock mode
- [ ] Implement server-side callbacks
- [ ] Add transaction verification
- [ ] Test with real M-Pesa account
- [ ] Implement proper error monitoring
- [ ] Add payment receipt generation

## 📞 Support

For M-Pesa API documentation and support:

- [Safaricom Developer Portal](https://developer.safaricom.co.ke/)
- [Daraja API Documentation](https://developer.safaricom.co.ke/docs)

---

✅ **Ready to use!** The M-Pesa integration is now complete and ready for testing.
