import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../common/app_image.dart';

/// "View cart" pill that slides up whenever the cart has items.
class FloatingCartBar extends ConsumerWidget {
  const FloatingCartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider).valueOrNull;
    final count = cart?.totalQuantity ?? 0;
    final visible = count > 0;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !visible,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Semantics(
              button: true,
              label: 'View cart, $count items',
              excludeSemantics: true,
              child: Material(
                color: AppColors.primary,
                borderRadius: AppRadius.lgAll,
                elevation: 6,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                child: InkWell(
                  borderRadius: AppRadius.lgAll,
                  onTap: () => context.go(AppRoutes.cart),
                  child: SizedBox(
                    height: AppSizes.floatingCartBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Row(
                        children: [
                          if (cart != null)
                            for (final item in cart.items.take(3))
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.xs),
                                child: SizedBox.square(
                                  dimension: 34,
                                  child: AppImage(
                                    url: item.product.imageUrl,
                                    borderRadius: AppRadius.smAll,
                                    background: Colors.white,
                                  ),
                                ),
                              ),
                          AppSpacing.gapSm,
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$count ${count == 1 ? 'item' : 'items'}',
                                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                ),
                                Text(
                                  // Line totals update instantly with the
                                  // stepper; the bill itself comes from the server.
                                  Formatters.currency(
                                    cart?.items.fold<double>(0, (sum, i) => sum + i.displayTotal) ?? 0,
                                  ),
                                  style: AppTextStyles.title.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'View cart',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
