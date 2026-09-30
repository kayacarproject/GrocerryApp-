import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/address.dart';
import '../../models/auth_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../screens/address/address_form_screen.dart';
import '../../screens/address/address_list_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_verification_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/category/categories_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/checkout/order_success_screen.dart';
import '../../screens/checkout/payment_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/orders/order_details_screen.dart';
import '../../screens/orders/order_tracking_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/product/product_details_screen.dart';
import '../../screens/product/product_listing_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/info_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/wishlist/wishlist_screen.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluates redirects whenever the auth status changes.
  final authStatus = ValueNotifier(ref.read(authProvider).status);
  ref.listen(
    authProvider.select((s) => s.status),
    (_, next) => authStatus.value = next,
  );
  ref.onDispose(authStatus.dispose);

  final cache = ref.read(localCacheProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    final status = ref.read(authProvider).status;
    final location = state.matchedLocation;
    final isPublic = AppRoutes.publicRoutes.contains(location);

    switch (status) {
      case AuthStatus.unknown:
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      case AuthStatus.unauthenticated:
        if (isPublic && location != AppRoutes.splash) return null;
        return cache.onboardingSeen ? AppRoutes.login : AppRoutes.onboarding;
      case AuthStatus.authenticated:
        return isPublic ? AppRoutes.home : null;
    }
  }

  GoRoute tab(String path, Widget screen, {List<RouteBase> routes = const []}) =>
      GoRoute(path: path, pageBuilder: (_, _) => NoTransitionPage(child: screen), routes: routes);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authStatus,
    redirect: redirect,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.otp,
        redirect: (_, state) => state.extra is OtpChallenge ? null : AppRoutes.login,
        builder: (_, state) => OtpVerificationScreen(challenge: state.extra! as OtpChallenge),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        redirect: (_, state) => state.extra is PasswordResetTicket ? null : AppRoutes.login,
        builder: (_, state) => ResetPasswordScreen(ticket: state.extra! as PasswordResetTicket),
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              tab(
                AppRoutes.home,
                const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'order-success/:id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) =>
                        OrderSuccessScreen(orderId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(routes: [tab(AppRoutes.categories, const CategoriesScreen())]),
          StatefulShellBranch(routes: [tab(AppRoutes.search, const SearchScreen())]),
          StatefulShellBranch(routes: [tab(AppRoutes.cart, const CartScreen())]),
          StatefulShellBranch(routes: [tab(AppRoutes.profile, const ProfileScreen())]),
        ],
      ),

      GoRoute(path: AppRoutes.location, builder: (_, _) => const AddressListScreen(selectMode: true)),
      GoRoute(
        path: '/category/:id',
        builder: (_, state) => ProductListingScreen(categoryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailsScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.wishlist, builder: (_, _) => const WishlistScreen()),
      GoRoute(
        path: AppRoutes.addresses,
        builder: (_, _) => const AddressListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const AddressFormScreen()),
          GoRoute(
            path: 'edit',
            redirect: (_, state) => state.extra is Address ? null : AppRoutes.addresses,
            builder: (_, state) => AddressFormScreen(initial: state.extra! as Address),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.checkout, builder: (_, _) => const CheckoutScreen()),
      GoRoute(
        path: '/payment/:id',
        builder: (_, state) => PaymentScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (_, _) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => OrderDetailsScreen(orderId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'track',
                builder: (_, state) =>
                    OrderTrackingScreen(orderId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, _) => const EditProfileScreen()),
      GoRoute(
        path: '/info/:page',
        builder: (_, state) => InfoScreen(
          page: InfoPage.values.firstWhere(
            (p) => p.name == state.pathParameters['page'],
            orElse: () => InfoPage.help,
          ),
        ),
      ),
    ],
  );
});
