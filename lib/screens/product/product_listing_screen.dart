import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../models/product_query.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/product_list_provider.dart';
// import '../../widgets/cart/floating_cart_bar.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/product/product_list_tile.dart';
import '../../widgets/product/product_sliver_grid.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/sort_sheet.dart';

class ProductListingScreen extends ConsumerStatefulWidget {
  const ProductListingScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  // View mode is purely presentational, so local state is appropriate.
  bool _gridView = true;

  String get _id => widget.categoryId;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 600) {
      ref.read(productListProvider(_id).notifier).loadMore();
    }
    return false;
  }

  Future<void> _pickSort() async {
    final params = ref.read(listingParamsProvider(_id));
    final sort = await showSortSheet(context, params.sort);
    if (sort != null) {
      ref.read(listingParamsProvider(_id).notifier).state = params.copyWith(sort: sort);
    }
  }

  Future<void> _pickFilter() async {
    final params = ref.read(listingParamsProvider(_id));
    final filter = await showFilterSheet(context, categoryId: _id, current: params.filter);
    if (filter != null) {
      ref.read(listingParamsProvider(_id).notifier).state = params.copyWith(filter: filter);
    }
  }

  void _clearFilters() {
    final params = ref.read(listingParamsProvider(_id));
    ref.read(listingParamsProvider(_id).notifier).state =
        params.copyWith(filter: ProductFilter.none);
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(categoryByIdProvider(_id));
    final params = ref.watch(listingParamsProvider(_id));
    final products = ref.watch(productListProvider(_id));
    final total = products.valueOrNull?.total;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category?.name ?? 'Products'),
            if (total != null)
              Text('$total products', style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _gridView ? 'Show as list' : 'Show as grid',
            icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _Toolbar(
            sortLabel: params.sort.label,
            filterCount: params.filter.activeCount,
            onSort: _pickSort,
            onFilter: _pickFilter,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: products.when(
              skipLoadingOnReload: false,
              loading: () => const SingleChildScrollView(child: ProductGridSkeleton()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(productListProvider(_id)),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No products found',
                    message: params.filter.activeCount > 0
                        ? 'Try removing some filters to see more products.'
                        : 'This category is empty right now. Check back soon!',
                    actionLabel: params.filter.activeCount > 0 ? 'Clear filters' : null,
                    onAction: params.filter.activeCount > 0 ? _clearFilters : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(productListProvider(_id).future),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                        if (_gridView)
                          ProductSliverGrid(products: data.items)
                        else
                          SliverPadding(
                            padding: AppSpacing.screen,
                            sliver: SliverList.separated(
                              itemCount: data.items.length,
                              separatorBuilder: (_, _) => AppSpacing.gapMd,
                              itemBuilder: (_, i) => ProductListTile(product: data.items[i]),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: _PageFooter(
                            isLoading: data.isLoadingMore,
                            error: data.loadMoreError,
                            hasMore: data.hasMore,
                            onRetry: () =>
                                ref.read(productListProvider(_id).notifier).loadMore(),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 90)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // TODO: Restore floating cart bar when ready.
          // const Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 0,
          //   child: SafeArea(top: false, child: FloatingCartBar()),
          // ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.sortLabel,
    required this.filterCount,
    required this.onSort,
    required this.onFilter,
  });

  final String sortLabel;
  final int filterCount;
  final VoidCallback onSort;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToolbarButton(
              icon: Icons.swap_vert_rounded,
              label: sortLabel,
              onTap: onSort,
              semanticLabel: 'Sort, currently $sortLabel',
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: _ToolbarButton(
              icon: Icons.tune_rounded,
              label: filterCount == 0 ? 'Filter' : 'Filter ($filterCount)',
              onTap: onFilter,
              highlighted: filterCount > 0,
              semanticLabel: 'Filter, $filterCount active',
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: highlighted ? AppColors.primaryLight : AppColors.surface,
        borderRadius: AppRadius.pillAll,
        child: InkWell(
          borderRadius: AppRadius.pillAll,
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillAll,
              border: Border.all(
                color: highlighted ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: highlighted ? AppColors.primary : AppColors.textSecondary),
                AppSpacing.gapXs,
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: highlighted ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({
    required this.isLoading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(error!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(child: Text('You\'ve seen it all 🎉', style: AppTextStyles.caption)),
      );
    }
    return const SizedBox(height: AppSpacing.xl);
  }
}
