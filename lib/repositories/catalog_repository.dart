import '../core/constants/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/storage/local_cache.dart';
import '../models/category.dart';
import '../models/home_feed.dart';
import '../models/pagination.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../services/api/catalog_api_service.dart';

abstract interface class CatalogRepository {
  Future<HomeFeed> getHomeFeed();
  Future<List<Category>> getCategories();
  Future<PaginatedList<Product>> getProducts(ProductQuery query);
  Future<FilterOptions> getFilterOptions(String categoryId);
  Future<Product> getProduct(String id);
  Future<List<Product>> getRelatedProducts(String id);
  Future<List<Product>> search(String term);
  Future<List<String>> getPopularSearches();
}

/// Talks to the API, keeping an offline copy of categories and the home feed
/// so the app still shows something useful without a connection.
class RemoteCatalogRepository implements CatalogRepository {
  const RemoteCatalogRepository(this._api, this._cache);

  final CatalogApiService _api;
  final LocalCache _cache;

  static const _bannerColors = ['#0E7C4A', '#2D5BD0', '#C2410C', '#7C3AED'];

  @override
  Future<HomeFeed> getHomeFeed() async {
    try {
      final results = await Future.wait([
        _api.getCollection(ApiEndpoints.dealProducts),
        _api.getCollection(ApiEndpoints.featuredProducts),
        _api.getCollection(ApiEndpoints.popularProducts),
        _api.getCollection(ApiEndpoints.latestProducts),
      ]);
      final [deals, featured, popular, latest] = results;
      final feed = HomeFeed(
        banners: _bannersFrom(deals),
        sections: [
          ProductSection(key: 'deals', title: 'Deals of the day', subtitle: 'Big savings, limited time', products: deals),
          ProductSection(key: 'featured', title: 'Featured picks', products: featured),
          ProductSection(key: 'popular', title: 'Best sellers', products: popular),
          ProductSection(key: 'latest', title: 'New arrivals', products: latest),
        ].where((s) => s.products.isNotEmpty).toList(),
      );
      await _cache.cacheHomeFeed(feed.toJson());
      return feed;
    } on ApiException catch (e) {
      final cached = _cache.cachedHomeFeed;
      if (e.isNetworkError && cached != null) return HomeFeed.fromJson(cached);
      rethrow;
    }
  }

  /// One banner per category that has the strongest current deal.
  static List<PromoBanner> _bannersFrom(List<Product> deals) {
    final bestByCategory = <String, Product>{};
    for (final p in deals.where((p) => p.hasDiscount && p.categoryId.isNotEmpty)) {
      final best = bestByCategory[p.categoryId];
      if (best == null || p.discountPercent > best.discountPercent) bestByCategory[p.categoryId] = p;
    }
    final picks = bestByCategory.values.toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return [
      for (final (i, p) in picks.take(4).indexed)
        PromoBanner(
          id: 'deal-${p.categoryId}',
          title: 'Up to ${p.discountPercent}% off\non ${p.categoryName}',
          subtitle: 'Deals of the day',
          imageUrl: p.imageUrl,
          categoryId: p.categoryId,
          colorHex: _bannerColors[i % _bannerColors.length],
        ),
    ];
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      final categories = await _api.getCategories();
      await _cache.cacheCategories(categories.map((c) => c.toJson()).toList());
      return categories;
    } on ApiException catch (e) {
      final cached = _cache.cachedCategories;
      if (e.isNetworkError && cached.isNotEmpty) {
        return cached.map(Category.fromJson).toList();
      }
      rethrow;
    }
  }

  @override
  Future<PaginatedList<Product>> getProducts(ProductQuery query) async {
    final page = await _api.getProducts(query);
    final filter = query.filter;
    if (!filter.hasClientSideFilters) return page;
    // Discount / availability aren't API filters yet; applied per page.
    return PaginatedList(
      items: page.items.where(filter.matchesClientSide).toList(),
      pagination: page.pagination,
    );
  }

  @override
  Future<FilterOptions> getFilterOptions(String categoryId) async {
    final page = await _api.getProducts(
      ProductQuery(categoryId: categoryId, perPage: 100),
    );
    if (page.items.isEmpty) return const FilterOptions();
    final prices = page.items.map((p) => p.price);
    return FilterOptions(
      brands: page.items.map((p) => p.brand).where((b) => b.isNotEmpty).toSet().toList()..sort(),
      minPrice: prices.reduce((a, b) => a < b ? a : b).floorToDouble(),
      maxPrice: prices.reduce((a, b) => a > b ? a : b).ceilToDouble(),
    );
  }

  @override
  Future<Product> getProduct(String id) => _api.getProduct(id);

  /// Other products from the same category.
  @override
  Future<List<Product>> getRelatedProducts(String id) async {
    final product = await _api.getProduct(id);
    if (product.categoryId.isEmpty) return const [];
    final page = await _api.getProducts(
      ProductQuery(categoryId: product.categoryId, perPage: 12),
    );
    return page.items.where((p) => p.id != id).toList();
  }

  @override
  Future<List<Product>> search(String term) => _api.search(term);

  /// Top brands among popular products make good one-tap searches.
  @override
  Future<List<String>> getPopularSearches() async {
    final popular = await _api.getCollection(ApiEndpoints.popularProducts, perPage: 20);
    return popular.map((p) => p.brand).where((b) => b.isNotEmpty).toSet().take(8).toList();
  }
}
