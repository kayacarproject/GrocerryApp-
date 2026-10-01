import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../models/product.dart';
import '../common/app_image.dart';
// import 'add_to_cart_button.dart';
import 'price_view.dart';
import 'wishlist_button.dart';

/// Vertical product card for grids and horizontal rails.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  static const _imageAspectRatio = AppSizes.productImageAspectRatio;

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.product(product.id)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _imageAspectRatio,
                    child: AppImage(
                      url: product.imageUrl,
                      borderRadius: AppRadius.mdAll,
                      semanticLabel: product.name,
                      background: product.inStock ? null : AppColors.surfaceMuted,
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: DiscountBadge(percent: product.discountPercent),
                    ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: WishlistButton(product: product, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _DeliveryTag(minutes: product.deliveryMinutes),
              const SizedBox(height: AppSpacing.xs),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(height: 1.3),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                product.unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PriceView(price: product.price, mrp: product.mrp),
                  ),
                  // TODO: Restore add to cart when ready.
                  // AddToCartButton(product: product),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryTag extends StatelessWidget {
  const _DeliveryTag({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.xsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 2),
          Text(
            '$minutes MINS',
            style: AppTextStyles.caption.copyWith(
              fontSize: 9.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
