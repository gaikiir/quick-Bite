import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MpesaConfig {
  // Sandbox URLs - Replace with production URLs for live environment
  static const String baseUrl = 'https://sandbox.safaricom.co.ke';
  static const String authUrl =
      '$baseUrl/oauth/v1/generate?grant_type=client_credentials';
  static const String stkPushUrl = '$baseUrl/mpesa/stkpush/v1/processrequest';
  static const String queryUrl = '$baseUrl/mpesa/stkpushquery/v1/query';

  // These should be stored securely in environment variables or secure storage
  // For demo purposes, I'm including them here - in production, use Flutter Secure Storage
  static const String consumerKey =
      'YOUR_CONSUMER_KEY'; // Replace with your actual key
  static const String consumerSecret =
      'YOUR_CONSUMER_SECRET'; // Replace with your actual secret
  static const String businessShortCode = '174379'; // Sandbox shortcode
  static const String passkey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'; // Sandbox passkey
  static const String callbackUrl =
      'https://your-domain.com/callback'; // Replace with your callback URL

  // Production values should be different
  static const bool isProduction = false;
}

class MpesaResponse {
  final bool success;
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final String? responseDescription;
  final String? customerMessage;
  final String? responseCode;
  final String? errorMessage;

  MpesaResponse({
    required this.success,
    this.checkoutRequestId,
    this.merchantRequestId,
    this.responseDescription,
    this.customerMessage,
    this.responseCode,
    this.errorMessage,
  });

  factory MpesaResponse.fromJson(Map<String, dynamic> json) {
    final isSuccess =
        json['ResponseCode'] == '0' || json['responseCode'] == '0';

    return MpesaResponse(
      success: isSuccess,
      checkoutRequestId: json['CheckoutRequestID'] ?? json['checkoutRequestID'],
      merchantRequestId: json['MerchantRequestID'] ?? json['merchantRequestID'],
      responseDescription:
          json['ResponseDescription'] ?? json['responseDescription'],
      customerMessage: json['CustomerMessage'] ?? json['customerMessage'],
      responseCode: json['ResponseCode'] ?? json['responseCode'],
      errorMessage: isSuccess
          ? null
          : (json['errorMessage'] ?? 'Payment failed'),
    );
  }
}

class MpesaPaymentStatus {
  final String resultCode;
  final String resultDesc;
  final String? mpesaReceiptNumber;
  final double? amount;
  final String? transactionDate;
  final String? phoneNumber;

  MpesaPaymentStatus({
    required this.resultCode,
    required this.resultDesc,
    this.mpesaReceiptNumber,
    this.amount,
    this.transactionDate,
    this.phoneNumber,
  });

  bool get isSuccess => resultCode == '0';
  bool get isCancelled => resultCode == '1032';
  bool get isTimeout => resultCode == '1037';

  factory MpesaPaymentStatus.fromCallbackData(Map<String, dynamic> data) {
    final body = data['Body'] ?? {};
    final stkCallback = body['stkCallback'] ?? {};
    final metadata = stkCallback['CallbackMetadata'] ?? {};
    final items = metadata['Item'] as List? ?? [];

    String? mpesaReceiptNumber;
    double? amount;
    String? transactionDate;
    String? phoneNumber;

    for (var item in items) {
      switch (item['Name']) {
        case 'MpesaReceiptNumber':
          mpesaReceiptNumber = item['Value']?.toString();
          break;
        case 'Amount':
          amount = double.tryParse(item['Value']?.toString() ?? '');
          break;
        case 'TransactionDate':
          transactionDate = item['Value']?.toString();
          break;
        case 'PhoneNumber':
          phoneNumber = item['Value']?.toString();
          break;
      }
    }

    return MpesaPaymentStatus(
      resultCode: stkCallback['ResultCode']?.toString() ?? '1',
      resultDesc: stkCallback['ResultDesc'] ?? 'Unknown error',
      mpesaReceiptNumber: mpesaReceiptNumber,
      amount: amount,
      transactionDate: transactionDate,
      phoneNumber: phoneNumber,
    );
  }
}

class MpesaService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // Format phone number to M-Pesa format (254XXXXXXXXX)
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle different formats
    if (digits.startsWith('254')) {
      return digits;
    } else if (digits.startsWith('0')) {
      return '254${digits.substring(1)}';
    } else if (digits.length == 9) {
      return '254$digits';
    }

    throw ArgumentError('Invalid phone number format: $phoneNumber');
  }

  // Get OAuth access token
  static Future<String?> _getAccessToken() async {
    try {
      // Check if token is still valid
      if (_accessToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken;
      }

      debugPrint('Getting new M-Pesa access token...');

      final credentials = base64Encode(
        utf8.encode('${MpesaConfig.consumerKey}:${MpesaConfig.consumerSecret}'),
      );

      final response = await http.get(
        Uri.parse(MpesaConfig.authUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        // Token expires in 1 hour, set expiry to 55 minutes for safety
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));

        debugPrint('M-Pesa access token obtained successfully');
        return _accessToken;
      } else {
        debugPrint(
          'Failed to get access token: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  // Generate password for STK push
  static String _generatePassword() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^\d]'), '')
        .substring(0, 14);

    final password = base64Encode(
      utf8.encode(
        '${MpesaConfig.businessShortCode}${MpesaConfig.passkey}$timestamp',
      ),
    );

    return password;
  }

  // Get current timestamp
  static String _getTimestamp() {
    return DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^\d]'), '')
        .substring(0, 14);
  }

  // Initiate STK push
  static Future<MpesaResponse> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      debugPrint(
        'Initiating STK push for phone: $phoneNumber, amount: $amount',
      );

      // Get access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return MpesaResponse(
          success: false,
          errorMessage: 'Failed to get access token',
        );
      }

      // Format phone number
      final formattedPhone = formatPhoneNumber(phoneNumber);

      // Generate password and timestamp
      final password = _generatePassword();
      final timestamp = _getTimestamp();

      final requestBody = {
        'BusinessShortCode': MpesaConfig.businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt(),
        'PartyA': formattedPhone,
        'PartyB': MpesaConfig.businessShortCode,
        'PhoneNumber': formattedPhone,
        'CallBackURL': MpesaConfig.callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc,
      };

      debugPrint('STK push request body: $requestBody');

      final response = await http.post(
        Uri.parse(MpesaConfig.stkPushUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint(
        'STK push response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MpesaResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        return MpesaResponse(
          success: false,
          errorMessage: errorData['errorMessage'] ?? 'Payment request failed',
        );
      }
    } catch (e) {
      debugPrint('Error initiating STK push: $e');
      return MpesaResponse(
        success: false,
        errorMessage: 'Failed to initiate payment: $e',
      );
    }
  }

  // Query STK push status
  static Future<MpesaPaymentStatus?> querySTKPushStatus({
    required String checkoutRequestId,
  }) async {
    try {
      debugPrint('Querying STK push status for: $checkoutRequestId');

      // Get access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('Failed to get access token for status query');
        return null;
      }

      // Generate password and timestamp
      final password = _generatePassword();
      final timestamp = _getTimestamp();

      final requestBody = {
        'BusinessShortCode': MpesaConfig.businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };

      final response = await http.post(
        Uri.parse(MpesaConfig.queryUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint(
        'Status query response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return MpesaPaymentStatus(
          resultCode: data['ResultCode']?.toString() ?? '1',
          resultDesc: data['ResultDesc'] ?? 'Unknown status',
        );
      } else {
        debugPrint('Failed to query payment status: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error querying STK push status: $e');
      return null;
    }
  }

  // Simulate payment callback for testing (remove in production)
  static Future<MpesaPaymentStatus> simulatePaymentCallback({
    required String checkoutRequestId,
    required bool success,
    String? mpesaReceiptNumber,
    double? amount,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    if (success) {
      return MpesaPaymentStatus(
        resultCode: '0',
        resultDesc: 'The service request is processed successfully.',
        mpesaReceiptNumber: mpesaReceiptNumber ?? 'PGR12345678',
        amount: amount,
        transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: '254700000000',
      );
    } else {
      return MpesaPaymentStatus(
        resultCode: '1032',
        resultDesc: 'Request cancelled by user',
      );
    }
  }

  // Validate M-Pesa configuration
  static bool validateConfig() {
    if (MpesaConfig.consumerKey == 'YOUR_CONSUMER_KEY' ||
        MpesaConfig.consumerSecret == 'YOUR_CONSUMER_SECRET') {
      debugPrint('M-Pesa configuration not set. Please update MpesaConfig.');
      return false;
    }
    return true;
  }
}
