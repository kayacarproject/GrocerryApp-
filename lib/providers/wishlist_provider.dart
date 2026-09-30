import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/wishlist_item.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>(
      WishlistNotifier.new,
    );

final wishlistIdsProvider = Provider<Set<String>>(
  (ref) =>
      ref.watch(wishlistProvider).valueOrNull?.map((i) => i.product.id).toSet() ??
      const {},
);

final isWishlistedProvider = Provider.family<bool, String>(
  (ref, productId) => ref.watch(wishlistIdsProvider).contains(productId),
);

class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  @override
  Future<List<WishlistItem>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.read(wishlistRepositoryProvider).getWishlist();
  }

  /// Optimistically toggles and reverts if the server rejects it.
  /// Returns `true` if the product is now wishlisted.
  Future<bool> toggle(Product product) async {
    final previous = state.valueOrNull ?? const <WishlistItem>[];
    final isSaved = previous.any((i) => i.product.id == product.id);
    state = AsyncData(
      isSaved
          ? previous.where((i) => i.product.id != product.id).toList()
          : [WishlistItem(product: product, addedAt: DateTime.now()), ...previous],
    );
    try {
      final repo = ref.read(wishlistRepositoryProvider);
      isSaved ? await repo.remove(product.id) : await repo.add(product.id);
      return !isSaved;
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> remove(Product product) async {
    if (ref.read(isWishlistedProvider(product.id))) await toggle(product);
  }
}
