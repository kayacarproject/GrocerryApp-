import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import '../../models/category.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/category/category_tile.dart';
import '../../widgets/common/async_value_view.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeletons.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('All categories'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(categoriesProvider.future),
        child: AsyncValueView<List<Category>>(
          value: categories,
          onRetry: () => ref.invalidate(categoriesProvider),
          loading: const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: CategoryGridSkeleton(count: 12, columns: 3),
          ),
          data: (list) => list.isEmpty
              ? const EmptyStateView(
                  icon: Icons.category_outlined,
                  title: 'No categories yet',
                  message: 'Please check back soon.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 4 : 3;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        110,
                      ),
                      itemCount: list.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (_, i) => CategoryCard(category: list[i]),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
