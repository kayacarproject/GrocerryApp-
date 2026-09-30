// Smoke test against the real backend. Skipped by default; run with:
//   LIVE_API=1 flutter test test/live_api_test.dart
// Uses the dev server's seeded customer and cleans up the cart afterwards.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:groceryshop/core/constants/app_strings.dart';
import 'package:groceryshop/core/network/api_client.dart';
import 'package:groceryshop/core/network/api_exception.dart';
import 'package:groceryshop/core/storage/token_storage.dart';
import 'package:groceryshop/models/product_query.dart';
import 'package:groceryshop/repositories/address_repository.dart';
import 'package:groceryshop/repositories/auth_repository.dart';
import 'package:groceryshop/repositories/cart_repository.dart';
import 'package:groceryshop/repositories/order_repository.dart';
import 'package:groceryshop/repositories/wishlist_repository.dart';
import 'package:groceryshop/services/api/address_api_service.dart';
import 'package:groceryshop/services/api/auth_api_service.dart';
import 'package:groceryshop/services/api/cart_api_service.dart';
import 'package:groceryshop/services/api/catalog_api_service.dart';
import 'package:groceryshop/services/api/notification_api_service.dart';
import 'package:groceryshop/services/api/order_api_service.dart';
import 'package:groceryshop/services/api/wishlist_api_service.dart';

/// Keeps tokens in memory; the keystore plugin isn't available in tests.
class _MemoryTokens extends TokenStorage {
  String? _token;

  @override
  Future<String?> get accessToken async => _token;
  @override
  Future<String?> get refreshToken async => null;
  @override
  Future<bool> get hasSession async => _token != null;
  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async =>
      _token = accessToken;
  @override
  Future<void> clear() async => _token = null;
}

void main() {
  final skip = Platform.environment['LIVE_API'] != '1';

  test('customer journey against the live API', () async {
    final tokens = _MemoryTokens();
    final client = ApiClient(tokenStorage: tokens);
    final auth = RemoteAuthRepository(AuthApiService(client), tokens);
    final catalog = CatalogApiService(client);
    final cart = RemoteCartRepository(CartApiService(client));
    final wishlist = RemoteWishlistRepository(WishlistApiService(client));
    final addresses = RemoteAddressRepository(AddressApiService(client));
    final orders = RemoteOrderRepository(OrderApiService(client));

    await expectLater(
      auth.login(email: AppStrings.devApiEmail, password: 'wrong-password'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Invalid credentials')),
    );
    final user = await auth.login(email: AppStrings.devApiEmail, password: AppStrings.devApiPassword);
    expect(user.email, AppStrings.devApiEmail);

    final categories = await catalog.getCategories();
    expect(categories, isNotEmpty);
    final page = await catalog.getProducts(
      ProductQuery(categoryId: categories.first.id, sort: ProductSort.priceLowToHigh),
    );
    expect(page.items, isNotEmpty);
    final product = await catalog.getProduct(page.items.first.id);
    expect(product.imageUrl, startsWith('http'));
    expect(await catalog.search('a'), isNotEmpty);

    // Cart: add, update, remove via product ids.
    var c = await cart.getCart();
    c = await cart.setQuantity(product.id, 2);
    expect(c.quantityOf(product.id), 2);
    c = await cart.setQuantity(product.id, 3);
    expect(c.quantityOf(product.id), 3);
    expect(c.summary.subtotal, greaterThan(0));

    final coupons = await cart.getCoupons();
    expect(coupons, isNotEmpty);

    final saved = await addresses.getAddresses();
    if (saved.isNotEmpty) {
      final preview = await cart.preview(addressId: saved.first.id);
      expect(preview.summary.includesCharges, isTrue);
      expect(preview.summary.total, greaterThan(0));
    }

    c = await cart.setQuantity(product.id, 0);
    expect(c.quantityOf(product.id), 0);

    await wishlist.add(product.id);
    expect((await wishlist.getWishlist()).any((w) => w.product.id == product.id), isTrue);
    await wishlist.remove(product.id);

    final history = await orders.getOrders();
    if (history.items.isNotEmpty) {
      final tracked = await orders.getTracking(history.items.first.id);
      expect(tracked.statusHistory, isNotEmpty);
    }
    await NotificationApiService(client).getNotifications();

    await auth.logout();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
