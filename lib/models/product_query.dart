import 'product.dart';

enum ProductSort {
  popularity('popular', 'Popularity'),
  priceLowToHigh('price_low', 'Price: Low to High'),
  priceHighToLow('price_high', 'Price: High to Low'),
  rating('rating', 'Customer Rating'),
  newest('newest', 'Newest First'),
  discount('discount', 'Discount');

  const ProductSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// User-selected listing filters. Immutable; use [copyWith].
class ProductFilter {
  const ProductFilter({
    this.minPrice,
    this.maxPrice,
    this.brands = const {},
    this.minRating,
    this.minDiscount,
    this.inStockOnly = false,
  });

  final double? minPrice;
  final double? maxPrice;
  final Set<String> brands;
  final double? minRating;
  final int? minDiscount;
  final bool inStockOnly;

  static const none = ProductFilter();

  int get activeCount =>
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (brands.isNotEmpty ? 1 : 0) +
      (minRating != null ? 1 : 0) +
      (minDiscount != null ? 1 : 0) +
      (inStockOnly ? 1 : 0);

  ProductFilter copyWith({
    double? Function()? minPrice,
    double? Function()? maxPrice,
    Set<String>? brands,
    double? Function()? minRating,
    int? Function()? minDiscount,
    bool? inStockOnly,
  }) => ProductFilter(
    minPrice: minPrice != null ? minPrice() : this.minPrice,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    brands: brands ?? this.brands,
    minRating: minRating != null ? minRating() : this.minRating,
    minDiscount: minDiscount != null ? minDiscount() : this.minDiscount,
    inStockOnly: inStockOnly ?? this.inStockOnly,
  );

  /// Filters the API supports. It accepts a single `brand`; discount and
  /// availability are applied to results by [matchesClientSide].
  Map<String, dynamic> toQueryParameters() => {
    if (minPrice != null) 'min_price': minPrice!.round(),
    if (maxPrice != null) 'max_price': maxPrice!.round(),
    if (brands.isNotEmpty) 'brand': brands.first,
    if (minRating != null) 'rating': minRating,
  };

  bool get hasClientSideFilters => minDiscount != null || inStockOnly;

  bool matchesClientSide(Product product) =>
      (minDiscount == null || product.discountPercent >= minDiscount!) &&
      (!inStockOnly || product.inStock);
}

class ProductQuery {
  const ProductQuery({
    this.categoryId,
    this.sort = ProductSort.popularity,
    this.filter = ProductFilter.none,
    this.page = 1,
    this.perPage = 20,
  });

  final String? categoryId;
  final ProductSort sort;
  final ProductFilter filter;
  final int page;
  final int perPage;

  ProductQuery copyWith({ProductSort? sort, ProductFilter? filter, int? page}) =>
      ProductQuery(
        categoryId: categoryId,
        sort: sort ?? this.sort,
        filter: filter ?? this.filter,
        page: page ?? this.page,
        perPage: perPage,
      );

  Map<String, dynamic> toQueryParameters() => {
    'sort': sort.apiValue,
    'page': page,
    'per_page': perPage,
    ...filter.toQueryParameters(),
  };
}

/// Facets available for filtering a category.
class FilterOptions {
  const FilterOptions({
    this.brands = const [],
    this.minPrice = 0,
    this.maxPrice = 1000,
  });

  factory FilterOptions.fromJson(Map<String, dynamic> json) => FilterOptions(
    brands: (json['brands'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    minPrice: (json['min_price'] as num?)?.toDouble() ?? 0,
    maxPrice: (json['max_price'] as num?)?.toDouble() ?? 1000,
  );

  final List<String> brands;
  final double minPrice;
  final double maxPrice;

  Map<String, dynamic> toJson() => {
    'brands': brands,
    'min_price': minPrice,
    'max_price': maxPrice,
  };
}
