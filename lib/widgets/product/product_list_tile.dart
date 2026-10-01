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

/// Horizontal product row for list mode, search results and wishlist.
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    this.trailing,
    this.showWishlist = true,
  });

  final Product product;

  /// Replaces the default add-to-cart control.
  final Widget? trailing;
  final bool showWishlist;

  @override
  Widget build(BuildContext context) {
    final imageSize = (MediaQuery.sizeOf(context).width * 0.24).clamp(80.0, 110.0);
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => context.push(AppRoutes.product(product.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox.square(
                    dimension: imageSize,
                    child: AppImage(
                      url: product.imageUrl,
                      borderRadius: AppRadius.mdAll,
                      semanticLabel: product.name,
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: DiscountBadge(percent: product.discountPercent),
                    ),
                ],
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.brand.isNotEmpty)
                                Text(product.brand, style: AppTextStyles.caption),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.title,
                              ),
                            ],
                          ),
                        ),
                        if (showWishlist)
                          WishlistButton(
                            product: product,
                            size: 20,
                            filledBackground: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(product.unit, style: AppTextStyles.bodySmall),
                    if (product.rating > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      RatingBadge(rating: product.rating, reviewCount: product.reviewCount),
                    ],
                    AppSpacing.gapSm,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: PriceView(price: product.price, mrp: product.mrp),
                        ),
                        // TODO: Restore add to cart when ready.
                        // trailing ?? AddToCartButton(product: product),
                        ?trailing,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
