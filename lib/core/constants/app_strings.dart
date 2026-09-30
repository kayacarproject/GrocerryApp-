/// Static UI copy. Kept in one place so it can move to ARB files for
/// localisation later.
abstract final class AppStrings {
  static const tagline = 'Fresh groceries, delivered in minutes';
  static const searchHint = 'Search for products...';
  static const genericError = 'Something went wrong. Please try again.';
  static const noInternet =
      'No internet connection. Check your network and try again.';

  // Test credentials, shown on the login screen in development builds only.
  // Offline demo backend:
  static const demoEmail = 'demo@basketly.app';
  static const demoPassword = 'Demo@1234';
  static const demoOtp = '123456';
  // Seeded customer on the development API server:
  static const devApiEmail = 'customer@grocery.test';
  static const devApiPassword = 'Customer@123';
}
