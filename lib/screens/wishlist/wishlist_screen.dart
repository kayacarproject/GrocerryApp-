import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../models/wishlist_item.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/common/async_value_view.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/product/add_to_cart_button.dart';
import '../../widgets/product/product_list_tile.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, WishlistItem item) async {
    try {
      await ref.read(wishlistProvider.notifier).remove(item.product);
      if (!context.mounted) return;
      context.showSnack(
        'Removed from wishlist',
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accent,
          onPressed: () => ref.read(wishlistProvider.notifier).toggle(item.product),
        ),
      );
    } catch (error) {
      if (context.mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My wishlist')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(wishlistProvider.future),
        child: AsyncValueView<List<WishlistItem>>(
          value: wishlist,
          onRetry: () => ref.invalidate(wishlistProvider),
          loading: const ListSkeleton(count: 4, item: TileSkeleton()),
          data: (items) => items.isEmpty
              ? EmptyStateView(
                  icon: Icons.favorite_border_rounded,
                  accent: AppColors.error,
                  title: 'Your wishlist is empty',
                  message: 'Tap the heart on any product to save it here for later.',
                  actionLabel: 'Explore products',
                  onAction: () => context.go(AppRoutes.home),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => AppSpacing.gapMd,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Dismissible(
                      key: ValueKey(item.product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        decoration: const BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: AppRadius.lgAll,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      ),
                      onDismissed: (_) => _remove(context, ref, item),
                      child: ProductListTile(
                        product: item.product,
                        showWishlist: false,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Remove from wishlist',
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
                              onPressed: () => _remove(context, ref, item),
                            ),
                            AddToCartButton(product: item.product),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
