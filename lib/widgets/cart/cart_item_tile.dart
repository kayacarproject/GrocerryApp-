import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../common/app_image.dart';
import '../product/add_to_cart_button.dart';

class CartItemTile extends ConsumerWidget {
  const CartItemTile({super.key, required this.item});

  final CartItem item;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(cartProvider.notifier).remove(item.product);
    } catch (error) {
      if (context.mounted) {
        context.showSnack(ApiException.messageOf(error), isError: true);
      }
    }
  }

  Future<void> _moveToWishlist(BuildContext context, WidgetRef ref) async {
    try {
      if (!ref.read(isWishlistedProvider(item.product.id))) {
        await ref.read(wishlistProvider.notifier).toggle(item.product);
      }
      await ref.read(cartProvider.notifier).remove(item.product);
      if (context.mounted) context.showSnack('Moved to wishlist');
    } catch (error) {
      if (context.mounted) {
        context.showSnack(ApiException.messageOf(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.product(product.id)),
            child: SizedBox.square(
              dimension: 68,
              child: AppImage(
                url: product.imageUrl,
                borderRadius: AppRadius.mdAll,
                semanticLabel: product.name,
              ),
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(product.unit, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.md,
                  children: [
                    _TextAction(
                      label: 'Remove',
                      icon: Icons.delete_outline_rounded,
                      onTap: () => _remove(context, ref),
                    ),
                    _TextAction(
                      label: 'Save for later',
                      icon: Icons.favorite_border_rounded,
                      onTap: () => _moveToWishlist(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AddToCartButton(product: product),
              AppSpacing.gapSm,
              Text(
                Formatters.currency(item.displayTotal),
                style: AppTextStyles.price,
              ),
              if (item.displayMrpTotal > item.displayTotal)
                Text(
                  Formatters.currency(item.displayMrpTotal),
                  style: AppTextStyles.strikePrice,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
