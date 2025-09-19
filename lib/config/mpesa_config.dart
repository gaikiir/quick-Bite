class MpesaConfig {
  // Working Sandbox credentials for testing
  static const String consumerKey =
      'FUSqGDhHFl9rc5u33rJAtpnKsuvX9rcgC9KA4u6YSgiGBzTL';
  static const String consumerSecret =
      'VwW7qdSmwzrt4lHTXMZS5d4G52bTdmYo0xgFT5bF07N9Lp5ilmxOpxTVCAZpLYjO';

  // Safaricom provided passkey (sandbox)
  static const String passkey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';

  // Business short code (sandbox: 174379, replace with your paybill for production)
  static const String businessShortCode = '174379';

  static const String callbackUrl = 'https://your-proxy-server.com/api/mpesa/callback';

  // Environment settings
  static const bool isProduction = false; // Set to true for production
  static const bool enableMockMode = false; // DISABLED for real API testing

  static const String? proxyUrl = 'http://localhost:5000/api/mpesa';

  // API Endpoints
  static const String baseUrl = isProduction
      ? 'https://api.safaricom.co.ke'
      : 'https://sandbox.safaricom.co.ke';

  static const String authUrl =
      '$baseUrl/oauth/v1/generate?grant_type=client_credentials';
  static const String stkPushUrl = '$baseUrl/mpesa/stkpush/v1/processrequest';
  static const String queryUrl = '$baseUrl/mpesa/stkpushquery/v1/query';

  // Transaction type
  static const String transactionType = 'CustomerPayBillOnline';

  // Helper method to validate configuration
  static bool get isConfigured {
    return consumerKey.isNotEmpty &&
        consumerSecret.isNotEmpty &&
        businessShortCode.isNotEmpty &&
        passkey.isNotEmpty;
  }
}
