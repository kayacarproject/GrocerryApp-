import '../../models/wishlist_item.dart';
import '../wishlist_repository.dart';
import 'mock_database.dart';

class MockWishlistRepository implements WishlistRepository {
  MockWishlistRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<WishlistItem>> getWishlist() async {
    await mockLatency(400);
    final entries = _db.wishlist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        if (_db.products[e.key] != null)
          WishlistItem(product: _db.products[e.key]!, addedAt: e.value),
    ];
  }

  @override
  Future<void> add(String productId) async {
    await mockLatency(250);
    _db.wishlist[productId] = DateTime.now();
    await _db.save();
  }

  @override
  Future<void> remove(String productId) async {
    await mockLatency(250);
    _db.wishlist.remove(productId);
    await _db.save();
  }
}
