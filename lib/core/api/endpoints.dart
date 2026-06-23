class Endpoints {
  // Auth
  static const String register    = '/v1/auth/register';
  static const String login       = '/v1/auth/login';
  static const String logout      = '/v1/auth/logout';
  static const String verifyOtp   = '/v1/auth/verify-otp';
  static const String resendOtp   = '/v1/auth/resend-otp';
  static const String me          = '/v1/auth/me';

  // Profile
  static const String profile        = '/v1/profile';
  static const String profilePhoto   = '/v1/profile/photo';
  static const String changePassword = '/v1/profile/change-password';
  static const String updatePin      = '/v1/profile/pin';

  // KYC
  static const String kycUpload = '/v1/kyc/upload';
  static const String kycStatus = '/v1/kyc/status';

  // Transfers
  static const String transferQuote = '/v1/transfers/quote';
  static const String transfers     = '/v1/transfers';

  // Beneficiaries
  static const String beneficiaries = '/v1/beneficiaries';

  // Cards (Stripe)
  static const String cards        = '/v1/cards';
  static const String setupIntent  = '/v1/cards/setup-intent';

  // Exchange rates
  static const String exchangeRates = '/v1/exchange-rates';
  static String exchangeRate(String from, String to) => '/v1/exchange-rates/$from/$to';

  // Countries & currencies
  static const String countries  = '/v1/countries';
  static const String currencies = '/v1/currencies';

  // Notifications
  static const String notifications        = '/v1/notifications';
  static const String notificationsReadAll = '/v1/notifications/read-all';
}
