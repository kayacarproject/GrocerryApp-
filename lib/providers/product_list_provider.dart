import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../models/pagination.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'repository_providers.dart';

/// Sort and filter selection for a category listing.
class ListingParams {
  const ListingParams({
    this.sort = ProductSort.popularity,
    this.filter = ProductFilter.none,
  });

  final ProductSort sort;
  final ProductFilter filter;

  ListingParams copyWith({ProductSort? sort, ProductFilter? filter}) =>
      ListingParams(sort: sort ?? this.sort, filter: filter ?? this.filter);
}

final listingParamsProvider = StateProvider.autoDispose
    .family<ListingParams, String>((ref, categoryId) => const ListingParams());

class ProductListData {
  const ProductListData({
    required this.items,
    required this.pagination,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Product> items;
  final Pagination pagination;
  final bool isLoadingMore;
  final String? loadMoreError;

  bool get hasMore => pagination.hasMore;
  int get total => pagination.total;

  ProductListData copyWith({
    List<Product>? items,
    Pagination? pagination,
    bool? isLoadingMore,
    String? Function()? loadMoreError,
  }) => ProductListData(
    items: items ?? this.items,
    pagination: pagination ?? this.pagination,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
  );
}

final productListProvider = AsyncNotifierProvider.autoDispose
    .family<ProductListNotifier, ProductListData, String>(
      ProductListNotifier.new,
    );

/// Paginated products for one category. Re-fetches from page 1 whenever the
/// sort or filter changes.
class ProductListNotifier
    extends AutoDisposeFamilyAsyncNotifier<ProductListData, String> {
  static const _pageSize = 12;

  ProductQuery _query(ListingParams params, int page) => ProductQuery(
    categoryId: arg,
    sort: params.sort,
    filter: params.filter,
    page: page,
    perPage: _pageSize,
  );

  @override
  Future<ProductListData> build(String categoryId) async {
    final params = ref.watch(listingParamsProvider(categoryId));
    final page = await ref
        .read(catalogRepositoryProvider)
        .getProducts(_query(params, 1));
    return ProductListData(items: page.items, pagination: page.pagination);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: () => null),
    );
    try {
      final params = ref.read(listingParamsProvider(arg));
      final next = await ref
          .read(catalogRepositoryProvider)
          .getProducts(_query(params, current.pagination.page + 1));
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next.items],
          pagination: next.pagination,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          loadMoreError: () => ApiException.messageOf(error),
        ),
      );
    }
  }
}
