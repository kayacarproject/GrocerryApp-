/// Every navigable path in the app. Screens navigate via these helpers rather
/// than hard-coded strings.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const resetPassword = '/reset-password';

  // Bottom navigation tabs
  static const home = '/home';
  static const categories = '/categories';
  static const search = '/search';
  static const cart = '/cart';
  static const profile = '/profile';

  static const location = '/location';
  static String category(String id) => '/category/$id';
  static String product(String id) => '/product/$id';
  static const wishlist = '/wishlist';
  static const addresses = '/addresses';
  static const addAddress = '/addresses/new';
  static const editAddress = '/addresses/edit';
  static const checkout = '/checkout';
  static String payment(String orderId) => '/payment/$orderId';
  // Nested under Home so leaving the success screen lands on Home.
  static String orderSuccess(String orderId) => '/home/order-success/$orderId';
  static const orders = '/orders';
  static String orderDetail(String id) => '/orders/$id';
  static String orderTracking(String id) => '/orders/$id/track';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static String info(InfoPage page) => '/info/${page.name}';

  /// Reachable without signing in.
  static const publicRoutes = {
    splash,
    onboarding,
    login,
    register,
    forgotPassword,
    otp,
    resetPassword,
  };
}

enum InfoPage {
  help('Help & Support'),
  payments('Payments'),
  privacy('Privacy Policy'),
  terms('Terms & Conditions'),
  about('About Basketly');

  const InfoPage(this.title);
  final String title;
}
