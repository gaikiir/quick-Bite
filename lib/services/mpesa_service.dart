import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/mpesa_config.dart';

/// Platform-aware M-Pesa Service that handles web CORS limitations
class MpesaService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  /// Check if we're running on web platform
  static bool get isWeb => kIsWeb;

  /// Format phone number to M-Pesa format (254XXXXXXXXX)
  static String formatPhoneNumber(String phoneNumber) {
    String digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.startsWith('254')) {
      return digits;
    } else if (digits.startsWith('0')) {
      return '254${digits.substring(1)}';
    } else if (digits.length == 9) {
      return '254$digits';
    }

    throw ArgumentError('Invalid phone number format: $phoneNumber');
  }

  /// Get OAuth access token from Daraja API
  /// For web: uses mock mode or proxy server
  /// For mobile: direct API call
  static Future<String?> getAccessToken() async {
    try {
      // Check if current token is still valid
      if (_accessToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        debugPrint('🔑 Using cached M-Pesa access token');
        return _accessToken;
      }

      debugPrint('🔑 Requesting new M-Pesa access token...');

      // Handle web platform differently due to CORS
      if (isWeb) {
        return await _getAccessTokenForWeb();
      } else {
        return await _getAccessTokenForMobile();
      }
    } catch (e) {
      debugPrint('💥 M-Pesa token request error: $e');
      return null;
    }
  }

  /// Get access token for web platform (uses proxy or mock)
  static Future<String?> _getAccessTokenForWeb() async {
    if (MpesaConfig.enableMockMode) {
      debugPrint('🎭 Web platform: Using mock access token');
      _accessToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
      return _accessToken;
    }

    // If you have a proxy server, use it here
    // Example: http://your-proxy-server.com/mpesa/token
    if (MpesaConfig.proxyUrl != null && MpesaConfig.proxyUrl!.isNotEmpty) {
      return await _getAccessTokenViaProxy();
    }

    // Fallback to mock for web
    debugPrint('⚠️ Web platform: No proxy configured, using mock mode');
    _accessToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
    return _accessToken;
  }

  /// Get access token for mobile platform (direct API call)
  static Future<String?> _getAccessTokenForMobile() async {
    try {
      // Create Basic Auth credentials
      final credentials = base64Encode(
        utf8.encode('${MpesaConfig.consumerKey}:${MpesaConfig.consumerSecret}'),
      );

      final response = await http
          .get(
            Uri.parse(MpesaConfig.authUrl),
            headers: {
              'Authorization': 'Basic $credentials',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        debugPrint('✅ M-Pesa access token obtained successfully');
        return _accessToken;
      } else {
        debugPrint('❌ Failed to get M-Pesa token: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 M-Pesa mobile token request error: $e');
      return null;
    }
  }

  /// Get access token via proxy server (for web with CORS handling)
  static Future<String?> _getAccessTokenViaProxy() async {
    try {
      final response = await http
          .post(
            Uri.parse('${MpesaConfig.proxyUrl}/token'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'consumerKey': MpesaConfig.consumerKey,
              'consumerSecret': MpesaConfig.consumerSecret,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        debugPrint('✅ M-Pesa access token obtained via proxy');
        return _accessToken;
      } else {
        debugPrint('❌ Proxy token request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('💥 Proxy token request error: $e');
      return null;
    }
  }

  /// Initiate STK Push payment with platform awareness
  static Future<MpesaResponse> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      debugPrint('💳 === M-PESA STK PUSH REQUEST ===');
      debugPrint('🌐 Platform: ${isWeb ? 'Web' : 'Mobile'}');
      debugPrint('📱 Phone: $phoneNumber');
      debugPrint('💰 Amount: KES $amount');

      // Handle mock mode for testing or web fallback
      if (MpesaConfig.enableMockMode ||
          (isWeb && MpesaConfig.proxyUrl == null)) {
        return await _mockSTKPush(
          phoneNumber: phoneNumber,
          amount: amount,
          accountReference: accountReference,
          transactionDesc: transactionDesc,
        );
      }

      // Validate configuration
      if (!MpesaConfig.isConfigured) {
        return MpesaResponse(
          success: false,
          errorMessage:
              'M-Pesa configuration incomplete. Please set your API credentials.',
        );
      }

      // Get access token
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return MpesaResponse(
          success: false,
          errorMessage: 'Failed to obtain access token',
        );
      }

      // Format phone number
      final formattedPhone = formatPhoneNumber(phoneNumber);

      if (isWeb && MpesaConfig.proxyUrl != null) {
        return await _initiateSTKPushViaProxy(
          phoneNumber: formattedPhone,
          amount: amount,
          accountReference: accountReference,
          transactionDesc: transactionDesc,
          accessToken: accessToken,
        );
      } else {
        return await _initiateSTKPushDirect(
          phoneNumber: formattedPhone,
          amount: amount,
          accountReference: accountReference,
          transactionDesc: transactionDesc,
          accessToken: accessToken,
        );
      }
    } catch (e) {
      debugPrint('💥 STK push error: $e');
      return MpesaResponse(success: false, errorMessage: 'Network error: $e');
    }
  }

  /// Mock STK Push for testing and web fallback
  static Future<MpesaResponse> _mockSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    debugPrint('🎭 Mock mode: Simulating STK push...');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Format phone number for validation
    try {
      final formattedPhone = formatPhoneNumber(phoneNumber);
      debugPrint('✅ Phone number validated: $formattedPhone');
    } catch (e) {
      return MpesaResponse(
        success: false,
        errorMessage: 'Invalid phone number format',
      );
    }

    // Simulate success
    final mockResponse = MpesaResponse(
      success: true,
      checkoutRequestId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      merchantRequestId: 'MR_${DateTime.now().millisecondsSinceEpoch}',
      responseDescription: 'Success. Request accepted for processing',
      customerMessage: 'Success. Request accepted for processing',
      responseCode: '0',
    );

    debugPrint('✅ Mock STK Push successful!');
    debugPrint('📱 In real scenario, user would receive STK push on phone');

    return mockResponse;
  }

  /// Direct STK Push for mobile platforms
  static Future<MpesaResponse> _initiateSTKPushDirect({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
    required String accessToken,
  }) async {
    // Generate password and timestamp
    final password = _generatePassword();
    final timestamp = _getTimestamp();

    // Prepare request body
    final requestBody = {
      'BusinessShortCode': MpesaConfig.businessShortCode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': MpesaConfig.transactionType,
      'Amount': amount.toInt(),
      'PartyA': phoneNumber,
      'PartyB': MpesaConfig.businessShortCode,
      'PhoneNumber': phoneNumber,
      'CallBackURL': MpesaConfig.callbackUrl,
      'AccountReference': accountReference,
      'TransactionDesc': transactionDesc,
    };

    debugPrint('📤 Sending direct STK push request...');
    debugPrint('🔗 URL: ${MpesaConfig.stkPushUrl}');
    debugPrint('🔐 Using token: ${accessToken.substring(0, 20)}...');

    final response = await http
        .post(
          Uri.parse(MpesaConfig.stkPushUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('📥 STK response: ${response.statusCode}');
    debugPrint('📥 Response body: ${response.body}');

    return _parseSTKResponse(response);
  }

  /// STK Push via proxy server for web platforms
  static Future<MpesaResponse> _initiateSTKPushViaProxy({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
    required String accessToken,
  }) async {
    final requestBody = {
      'phoneNumber': phoneNumber,
      'amount': amount.toInt(),
      'accountReference': accountReference,
      'transactionDesc': transactionDesc,
      'accessToken': accessToken,
    };

    debugPrint('📤 Sending STK push via proxy...');
    debugPrint('🔗 Proxy URL: ${MpesaConfig.proxyUrl}/stkpush');

    final response = await http
        .post(
          Uri.parse('${MpesaConfig.proxyUrl}/stkpush'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('📥 Proxy STK response: ${response.statusCode}');
    debugPrint('📥 Response body: ${response.body}');

    return _parseSTKResponse(response);
  }

  /// Parse STK Push response
  static MpesaResponse _parseSTKResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final mpesaResponse = MpesaResponse.fromJson(data);

      if (mpesaResponse.success) {
        debugPrint(
          '✅ STK Push successful! CheckoutRequestID: ${mpesaResponse.checkoutRequestId}',
        );
        debugPrint('📱 Check your phone for the STK push prompt');
      } else {
        debugPrint('❌ STK Push failed: ${mpesaResponse.errorMessage}');
      }

      return mpesaResponse;
    } else {
      debugPrint('❌ HTTP Error: ${response.statusCode}');
      debugPrint('❌ Error body: ${response.body}');

      try {
        final errorData = json.decode(response.body);
        return MpesaResponse(
          success: false,
          errorMessage:
              errorData['errorMessage'] ??
              'STK push failed with status ${response.statusCode}',
        );
      } catch (e) {
        return MpesaResponse(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    }
  }

  /// Generate password for STK push
  static String _generatePassword() {
    final timestamp = _getTimestamp();
    return base64Encode(
      utf8.encode(
        '${MpesaConfig.businessShortCode}${MpesaConfig.passkey}$timestamp',
      ),
    );
  }

  /// Get current timestamp in the required format
  static String _getTimestamp() {
    return DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^\d]'), '')
        .substring(0, 14);
  }

  /// Clear cached token (useful for testing)
  static void clearToken() {
    _accessToken = null;
    _tokenExpiry = null;
    debugPrint('🔄 M-Pesa access token cleared');
  }

  /// Get platform info for debugging
  static String getPlatformInfo() {
    return '''
🌐 Platform: ${isWeb ? 'Web' : 'Mobile'}
🎭 Mock Mode: ${MpesaConfig.enableMockMode}
🔗 Proxy URL: ${MpesaConfig.proxyUrl ?? 'Not configured'}
🔧 Config Valid: ${MpesaConfig.isConfigured}
🔑 Token Cached: ${_accessToken != null}
⏰ Token Expires: ${_tokenExpiry?.toIso8601String() ?? 'N/A'}
''';
  }
}

/// M-Pesa response model
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
    final isSuccess = json['ResponseCode'] == '0';
    return MpesaResponse(
      success: isSuccess,
      checkoutRequestId: json['CheckoutRequestID'],
      merchantRequestId: json['MerchantRequestID'],
      responseDescription: json['ResponseDescription'],
      customerMessage: json['CustomerMessage'],
      responseCode: json['ResponseCode'],
      errorMessage: isSuccess
          ? null
          : (json['errorMessage'] ??
                json['ResponseDescription'] ??
                'Payment failed'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'checkoutRequestId': checkoutRequestId,
      'merchantRequestId': merchantRequestId,
      'responseDescription': responseDescription,
      'customerMessage': customerMessage,
      'responseCode': responseCode,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'MpesaResponse{success: $success, checkoutRequestId: $checkoutRequestId, errorMessage: $errorMessage}';
  }
}
