import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/pagination.dart';
import '../../models/wishlist_item.dart';

class WishlistApiService {
  const WishlistApiService(this._client);

  final ApiClient _client;

  /// The API returns wishlisted products directly.
  Future<List<WishlistItem>> getWishlist() async {
    final response = await _client.get(
      ApiEndpoints.wishlist,
      query: {'page': 1, 'per_page': 100},
      decoder: (data) => PaginatedList.fromData(
        data,
        (json) => json.containsKey('product')
            ? WishlistItem.fromJson(json)
            : WishlistItem.fromProductJson(json),
      ),
    );
    return response.data.items;
  }

  Future<void> add(String productId) async {
    await _client.post(
      ApiEndpoints.wishlist,
      body: {'product_id': Json.id(productId)},
      decoder: (_) {},
    );
  }

  Future<void> remove(String productId) async {
    await _client.delete(ApiEndpoints.wishlistItem(productId), decoder: (_) {});
  }
}
