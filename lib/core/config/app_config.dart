/// Build-time configuration. Values are injected with `--dart-define`, e.g.
///
/// ```
/// flutter run --dart-define=USE_MOCK=false \
///   --dart-define=API_BASE_URL=https://api.example.com/v1 \
///   --dart-define=APP_ENV=production
/// ```
///
/// Never place secret keys here: anything compiled into the app can be
/// extracted from the binary.
abstract final class AppConfig {
  static const String appName = 'Basketly';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://grocery-api-zeta.vercel.app/api/v1',
  );

  /// Scheme + host (+ port) of [apiBaseUrl], used to resolve media URLs.
  static String get apiOrigin => Uri.parse(apiBaseUrl).origin;

  /// When true, repositories are backed by the offline demo backend in
  /// `lib/repositories/mock` instead of the REST API.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );

  /// Shows the notification bell, inbox and notification settings. Hidden for
  /// now; flip to true to bring them back.
  static const bool notificationsEnabled = false;

  /// Shows coupon entry in the cart and at checkout. Hidden for now.
  static const bool couponsEnabled = false;

  /// Offers UPI, card and net banking. While false, Cash on Delivery is the
  /// only payment method.
  static const bool onlinePaymentsEnabled = false;

  /// Shows the Help & Support, Privacy Policy and Terms & Conditions pages.
  /// Hidden for now.
  static const bool supportPagesEnabled = false;

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String appVersion = '1.0.0';
  static const String supportPhone = '+91 80000 00000';
  static const String supportEmail = 'support@basketly.app';
}
