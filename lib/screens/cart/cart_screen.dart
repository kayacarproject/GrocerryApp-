import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';
import '../../models/price_summary.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/cart/bill_summary_card.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../widgets/cart/coupon_section.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/async_value_view.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeletons.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final count = cart.valueOrNull?.totalQuantity ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(count == 0 ? 'My cart' : 'My cart ($count)'),
      ),
      body: AsyncValueView<Cart>(
        value: cart,
        onRetry: () => ref.invalidate(cartProvider),
        loading: const ListSkeleton(count: 3, item: TileSkeleton()),
        data: (cart) => cart.isEmpty
            ? EmptyStateView(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Looks like you haven\'t added anything yet. '
                    'Fresh groceries are just a tap away!',
                actionLabel: 'Start Shopping',
                onAction: () => context.go(AppRoutes.home),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(cartProvider.future),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _DeliveryBanner(summary: cart.summary),
                    AppSpacing.gapLg,
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        children: [
                          for (var i = 0; i < cart.items.length; i++) ...[
                            if (i > 0) const Divider(),
                            CartItemTile(
                              key: ValueKey(cart.items[i].product.id),
                              item: cart.items[i],
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppSpacing.gapLg,
                    if (AppConfig.couponsEnabled) ...[
                      const CouponSection(),
                      AppSpacing.gapLg,
                    ],
                    BillSummaryCard(summary: cart.summary, totalLabel: 'Item total'),
                    AppSpacing.gapLg,
                    Text(
                      'Prices and availability are confirmed at checkout. '
                      'Orders can be cancelled until they are being prepared.',
                      style: AppTextStyles.caption,
                    ),
                    AppSpacing.gapLg,
                  ],
                ),
              ),
      ),
      bottomNavigationBar: cart.valueOrNull?.isEmpty ?? true
          ? null
          : _CheckoutBar(total: cart.valueOrNull!.summary.total),
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner({required this.summary});

  final PriceSummary summary;

  @override
  Widget build(BuildContext context) {
    final remaining = summary.amountToFreeDelivery;
    final threshold = summary.freeDeliveryThreshold;
    return AppCard(
      color: AppColors.primaryLight,
      borderColor: AppColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.primary),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  'Delivery in 12 minutes',
                  style: AppTextStyles.title.copyWith(color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
          if (threshold != null) ...[
            AppSpacing.gapSm,
            Text(
              remaining > 0
                  ? 'Add ${Formatters.currency(remaining)} more for FREE delivery'
                  : 'Yay! You get FREE delivery on this order',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
            ),
            AppSpacing.gapSm,
            ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ((threshold - remaining) / threshold).clamp(0, 1).toDouble()),
                duration: const Duration(milliseconds: 400),
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4))],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Formatters.currency(total), style: AppTextStyles.h3),
                Text('Item total', style: AppTextStyles.caption),
              ],
            ),
            AppSpacing.gapLg,
            Expanded(
              child: AppButton(
                label: 'Proceed to Checkout',
                onPressed: () => context.push(AppRoutes.checkout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
