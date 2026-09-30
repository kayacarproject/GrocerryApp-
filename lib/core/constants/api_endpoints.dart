/// Relative REST paths. The host comes from `AppConfig.apiBaseUrl`.
abstract final class ApiEndpoints {
  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const sendOtp = '/auth/send-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const logout = '/auth/logout';
  static const me = '/auth/me';

  // The API issues long-lived tokens without refresh; kept for the
  // interceptor should the backend add one.
  static const refreshToken = '/auth/refresh';

  // User
  static const profile = '/user/profile';
  static const profileImage = '/user/profile-image';
  static const changePassword = '/user/change-password';

  // Catalog
  static const categories = '/categories';
  static String categoryProducts(String id) => '/categories/$id/products';
  static const products = '/products';
  static const featuredProducts = '/products/featured';
  static const popularProducts = '/products/popular';
  static const latestProducts = '/products/latest';
  static const dealProducts = '/products/deals';
  static const searchProducts = '/products/search';
  static String product(String id) => '/products/$id';

  // Cart
  static const cart = '/cart';
  static const cartItems = '/cart/items';
  static String cartItem(String cartItemId) => '/cart/items/$cartItemId';

  // Coupons & checkout
  static const coupons = '/coupons';
  static const validateCoupon = '/coupons/validate';
  static const checkoutPreview = '/checkout/preview';

  // Wishlist
  static const wishlist = '/wishlist';
  static String wishlistItem(String productId) => '/wishlist/$productId';

  // Addresses
  static const addresses = '/addresses';
  static String address(String id) => '/addresses/$id';
  static String defaultAddress(String id) => '/addresses/$id/default';

  // Orders & payments
  static const orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderTracking(String id) => '/orders/$id/tracking';
  static String cancelOrder(String id) => '/orders/$id/cancel';
  static const createPayment = '/payments/create';
  static const verifyPayment = '/payments/verify';

  // Notifications
  static const notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const notificationsReadAll = '/notifications/read-all';
}
