import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../repositories/cart_repository.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(CartNotifier.new);

final cartQuantityProvider = Provider.family<int, String>(
  (ref, productId) =>
      ref.watch(cartProvider).valueOrNull?.quantityOf(productId) ?? 0,
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).valueOrNull?.totalQuantity ?? 0,
);

/// Quantities update instantly (optimistic) while requests are serialised in
/// the background. The server's re-priced cart replaces local state once the
/// last pending request completes, so totals always come from the server.
class CartNotifier extends AsyncNotifier<Cart> {
  Future<void> _queue = Future.value();
  int _pending = 0;

  CartRepository get _repo => ref.read(cartRepositoryProvider);
  Cart get _current => state.valueOrNull ?? Cart.empty;

  /// True while local quantities are ahead of the server's totals.
  bool get isSyncing => _pending > 0;

  @override
  Future<Cart> build() async {
    if (ref.watch(currentUserIdProvider) == null) return Cart.empty;
    return _repo.getCart();
  }

  Future<void> setQuantity(Product product, int quantity) {
    state = AsyncData(_current.withQuantity(product, quantity));
    return _enqueue(() => _repo.setQuantity(product.id, quantity));
  }

  Future<void> add(Product product) =>
      setQuantity(product, _current.quantityOf(product.id) + 1);

  Future<void> decrement(Product product) =>
      setQuantity(product, _current.quantityOf(product.id) - 1);

  Future<void> remove(Product product) => setQuantity(product, 0);

  /// Re-fetches after the server cleared the cart (e.g. order placed).
  void reload() => ref.invalidateSelf();

  Future<void> _enqueue(Future<Cart> Function() request) {
    final completer = Completer<void>();
    _pending++;
    _queue = _queue.then((_) async {
      try {
        final cart = await request();
        _pending--;
        if (_pending == 0) state = AsyncData(cart);
        completer.complete();
      } catch (error, stack) {
        _pending--;
        if (_pending == 0) await _resync();
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<void> _resync() async {
    try {
      state = AsyncData(await _repo.getCart());
    } catch (_) {
      // Keep showing the last known cart; the next action will retry.
    }
  }
}
