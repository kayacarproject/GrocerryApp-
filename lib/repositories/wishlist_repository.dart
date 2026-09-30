import '../models/wishlist_item.dart';
import '../services/api/wishlist_api_service.dart';

abstract interface class WishlistRepository {
  Future<List<WishlistItem>> getWishlist();
  Future<void> add(String productId);
  Future<void> remove(String productId);
}

class RemoteWishlistRepository implements WishlistRepository {
  const RemoteWishlistRepository(this._api);

  final WishlistApiService _api;

  @override
  Future<List<WishlistItem>> getWishlist() => _api.getWishlist();

  @override
  Future<void> add(String productId) => _api.add(productId);

  @override
  Future<void> remove(String productId) => _api.remove(productId);
}
