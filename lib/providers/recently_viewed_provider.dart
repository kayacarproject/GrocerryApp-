import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

final recentlyViewedProvider =
    NotifierProvider<RecentlyViewedNotifier, List<Product>>(
      RecentlyViewedNotifier.new,
    );

/// Locally cached so it is available offline.
class RecentlyViewedNotifier extends Notifier<List<Product>> {
  static const _limit = 12;

  @override
  List<Product> build() {
    ref.watch(currentUserIdProvider);
    return ref
        .read(localCacheProvider)
        .recentlyViewed
        .map(Product.fromJson)
        .toList();
  }

  void add(Product product) {
    final updated = [
      product,
      ...state.where((p) => p.id != product.id),
    ].take(_limit).toList();
    state = updated;
    ref
        .read(localCacheProvider)
        .setRecentlyViewed(updated.map((p) => p.toJson()).toList());
  }

  void clear() {
    state = const [];
    ref.read(localCacheProvider).setRecentlyViewed(const []);
  }
}
