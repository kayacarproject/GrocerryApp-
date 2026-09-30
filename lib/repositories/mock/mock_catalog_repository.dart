import '../../core/network/api_exception.dart';
import '../../models/category.dart';
import '../../models/home_feed.dart';
import '../../models/pagination.dart';
import '../../models/product.dart';
import '../../models/product_query.dart';
import '../catalog_repository.dart';
import 'mock_catalog_data.dart';
import 'mock_database.dart';

class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository(this._db);

  final MockDatabase _db;

  List<Product> get _all => _db.products.values.toList();

  @override
  Future<HomeFeed> getHomeFeed() async {
    await mockLatency(800);
    final all = _all.where((p) => p.inStock).toList();
    List<Product> top(int Function(Product a, Product b) compare, [int count = 10]) =>
        ([...all]..sort(compare)).take(count).toList();

    final orderedIds = {
      for (final order in _db.orders) ...order.items.map((i) => i.productId),
    };
    final frequentlyBought = orderedIds
        .map((id) => _db.products[id])
        .whereType<Product>()
        .where((p) => p.inStock)
        .toList();

    return HomeFeed(
      banners: mockBanners,
      sections: [
        ProductSection(
          key: 'deals',
          title: 'Deals of the day',
          subtitle: 'Big savings, limited time',
          products: top((a, b) => b.discountPercent.compareTo(a.discountPercent)),
        ),
        ProductSection(
          key: 'best_sellers',
          title: 'Best sellers',
          products: top((a, b) => b.reviewCount.compareTo(a.reviewCount)),
        ),
        ProductSection(
          key: 'frequently_bought',
          title: 'Buy it again',
          subtitle: 'From your previous orders',
          products: frequentlyBought,
        ),
        ProductSection(
          key: 'popular',
          title: 'Popular near you',
          products: top((a, b) => (b.rating * b.reviewCount).compareTo(a.rating * a.reviewCount)),
        ),
        ProductSection(
          key: 'recommended',
          title: 'Recommended for you',
          products: top((a, b) => (a.id.hashCode % 97).compareTo(b.id.hashCode % 97)),
        ),
      ].where((s) => s.products.isNotEmpty).toList(),
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    await mockLatency(500);
    return [
      for (final c in mockCategories)
        Category(
          id: c.id,
          name: c.name,
          imageUrl: c.imageUrl,
          colorHex: c.colorHex,
          productCount: _all.where((p) => p.categoryId == c.id).length,
        ),
    ];
  }

  @override
  Future<PaginatedList<Product>> getProducts(ProductQuery query) async {
    await mockLatency(600);
    final f = query.filter;
    final results = _all.where((p) {
      if (query.categoryId != null && p.categoryId != query.categoryId) return false;
      if (f.minPrice != null && p.price < f.minPrice!) return false;
      if (f.maxPrice != null && p.price > f.maxPrice!) return false;
      if (f.brands.isNotEmpty && !f.brands.contains(p.brand)) return false;
      if (f.minRating != null && p.rating < f.minRating!) return false;
      if (f.minDiscount != null && p.discountPercent < f.minDiscount!) return false;
      if (f.inStockOnly && !p.inStock) return false;
      return true;
    }).toList();

    results.sort(switch (query.sort) {
      ProductSort.popularity => (a, b) => b.reviewCount.compareTo(a.reviewCount),
      ProductSort.priceLowToHigh => (a, b) => a.price.compareTo(b.price),
      ProductSort.priceHighToLow => (a, b) => b.price.compareTo(a.price),
      ProductSort.rating => (a, b) => b.rating.compareTo(a.rating),
      ProductSort.newest => (a, b) =>
          (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)),
      ProductSort.discount => (a, b) => b.discountPercent.compareTo(a.discountPercent),
    });

    final start = (query.page - 1) * query.perPage;
    final pageItems = results.skip(start).take(query.perPage).toList();
    return PaginatedList(
      items: pageItems,
      pagination: Pagination(
        page: query.page,
        perPage: query.perPage,
        total: results.length,
        lastPage: (results.length / query.perPage).ceil().clamp(1, 1 << 20),
      ),
    );
  }

  @override
  Future<FilterOptions> getFilterOptions(String categoryId) async {
    await mockLatency(200);
    final products = _all.where((p) => p.categoryId == categoryId).toList();
    if (products.isEmpty) return const FilterOptions();
    final prices = products.map((p) => p.price);
    return FilterOptions(
      brands: products.map((p) => p.brand).toSet().toList()..sort(),
      minPrice: prices.reduce((a, b) => a < b ? a : b).floorToDouble(),
      maxPrice: prices.reduce((a, b) => a > b ? a : b).ceilToDouble(),
    );
  }

  @override
  Future<Product> getProduct(String id) async {
    await mockLatency(500);
    final product = _db.products[id];
    if (product == null) {
      throw const ApiException(
        type: ApiErrorType.notFound,
        statusCode: 404,
        message: 'This product is no longer available.',
      );
    }
    return product;
  }

  @override
  Future<List<Product>> getRelatedProducts(String id) async {
    await mockLatency(500);
    final product = _db.products[id];
    if (product == null) return const [];
    return _all
        .where((p) => p.categoryId == product.categoryId && p.id != id)
        .take(8)
        .toList();
  }

  @override
  Future<List<Product>> search(String term) async {
    await mockLatency(450);
    final q = term.trim().toLowerCase();
    if (q.isEmpty) return const [];
    int score(Product p) {
      final name = p.name.toLowerCase();
      if (name.startsWith(q)) return 0;
      if (name.split(' ').any((w) => w.startsWith(q))) return 1;
      if (name.contains(q)) return 2;
      return 3;
    }

    final matches = _all.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.categoryName.toLowerCase().contains(q)).toList()
      ..sort((a, b) => score(a).compareTo(score(b)));
    return matches;
  }

  @override
  Future<List<String>> getPopularSearches() async {
    await mockLatency(200);
    return mockPopularSearches;
  }
}
