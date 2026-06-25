class AppConstants {
  static const String appName = 'AfriYuan';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrl = 'https://afriyuan.jss-gn.com/api/v1';
  static const int apiTimeoutSeconds = 30;

  // Stripe
  static const String stripePublishableKey =
      'pk_test_REPLACE_WITH_YOUR_STRIPE_PUBLISHABLE_KEY';

  // Supported source currencies (Africa)
  static const List<String> sourceCurrencies = [
    'XOF', 'XAF', 'GNF', 'GHS', 'LRD', 'SLE',
  ];

  // Destination currency (China)
  static const String destinationCurrency = 'CNY';

  // Supported source countries ISO codes
  static const List<String> sourceCountries = [
    'CI', 'SN', 'GW', 'GA', 'GN', 'GH', 'LR', 'SL',
  ];

  // Exchange rate refresh interval in minutes
  static const int exchangeRateTtlMinutes = 15;

  // KYC levels
  static const int kycLevelNone = 0;
  static const int kycLevelBasic = 1;
  static const int kycLevelFull = 2;

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String pinHashKey = 'pin_hash';
  static const String biometricEnabledKey = 'biometric_enabled';
}
