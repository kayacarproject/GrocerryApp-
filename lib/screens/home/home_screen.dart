import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import '../../models/category.dart';
import '../../models/home_feed.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/recently_viewed_provider.dart';
import '../../widgets/category/category_tile.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/search_bar_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/product/product_rail.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/home_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) {
    ref.invalidate(categoriesProvider);
    return ref.refresh(homeFeedProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              // Three lines of header text; grows with the user's font size.
              toolbarHeight: MediaQuery.textScalerOf(context).scale(62) + 14,
              titleSpacing: AppSpacing.lg,
              title: const HomeHeader(),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(66),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: SearchBarButton(onTap: () => context.go(AppRoutes.search)),
                ),
              ),
            ),
            ...feed.when(
              skipLoadingOnRefresh: true,
              loading: () => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: HomeSkeleton(),
                  ),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(homeFeedProvider),
                  ),
                ),
              ],
              data: (data) => _content(context, ref, data),
            ),
            // Room for the floating cart bar.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, HomeFeed feed) {
    final categories = ref.watch(categoriesProvider);
    final recentlyViewed = ref.watch(recentlyViewedProvider);

    Widget rail(ProductSection section) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: ProductRail(
          title: section.title,
          subtitle: section.subtitle,
          products: section.products,
        ),
      ),
    );

    final sections = feed.sections;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: BannerCarousel(banners: feed.banners),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
          child: SectionHeader(
            title: 'Shop by category',
            onAction: () => context.go(AppRoutes.categories),
          ),
        ),
      ),
      categories.when(
        loading: () => const SliverToBoxAdapter(child: CategoryGridSkeleton()),
        error: (error, _) => SliverToBoxAdapter(
          child: ErrorView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        ),
        data: (list) => _CategoryGrid(categories: list.take(8).toList()),
      ),
      // First rail, then recently viewed, then the rest.
      if (sections.isNotEmpty) rail(sections.first),
      if (recentlyViewed.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: ProductRail(
              title: 'Recently viewed',
              products: recentlyViewed,
            ),
          ),
        ),
      for (final section in sections.skip(1)) rail(section),
    ];
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: AppSpacing.screen,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          const columns = 4;
          const spacing = AppSpacing.md;
          final cell =
              (constraints.crossAxisExtent - spacing * (columns - 1)) / columns;
          return SliverGrid.builder(
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: AppSpacing.lg,
              mainAxisExtent: cell + MediaQuery.textScalerOf(context).scale(38),
            ),
            itemBuilder: (_, i) => CategoryTile(category: categories[i]),
          );
        },
      ),
    );
  }
}
