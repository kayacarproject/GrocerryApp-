import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/home_feed.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'repository_providers.dart';

final homeFeedProvider = FutureProvider<HomeFeed>(
  (ref) => ref.watch(catalogRepositoryProvider).getHomeFeed(),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).getCategories(),
);

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});

final productDetailProvider = FutureProvider.autoDispose.family<Product, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).getProduct(id),
);

final relatedProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>(
      (ref, id) => ref.watch(catalogRepositoryProvider).getRelatedProducts(id),
    );

final filterOptionsProvider =
    FutureProvider.autoDispose.family<FilterOptions, String>(
      (ref, categoryId) =>
          ref.watch(catalogRepositoryProvider).getFilterOptions(categoryId),
    );
