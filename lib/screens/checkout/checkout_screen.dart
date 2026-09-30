import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';
import '../../models/payment.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/cart/bill_summary_card.dart';
import '../../widgets/cart/coupon_section.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_image.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/order/payment_method_style.dart';
import '../address/widgets/address_card.dart';
import 'widgets/checkout_section.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    try {
      final order = await ref.read(checkoutProvider.notifier).placeOrder();
      if (!context.mounted) return;
      if (order.payment.method.isOnline) {
        context.pushReplacement(AppRoutes.payment(order.id));
      } else {
        context.go(AppRoutes.orderSuccess(order.id));
      }
    } catch (error) {
      if (context.mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);
    final preview = ref.watch(checkoutPreviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.when(
        loading: () => const ListSkeleton(count: 4, item: TileSkeleton()),
        error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(cartProvider)),
        data: (cart) => cart.isEmpty
            ? EmptyStateView(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Add a few items before checking out.',
                actionLabel: 'Start Shopping',
                onAction: () => context.go(AppRoutes.home),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const _AddressSection(),
                  AppSpacing.gapLg,
                  const _SlotSection(),
                  AppSpacing.gapLg,
                  _OrderSummarySection(cart: cart),
                  AppSpacing.gapLg,
                  if (AppConfig.couponsEnabled) ...[
                    const CheckoutSection(step: 4, title: 'Offers & coupons', child: CouponSection()),
                    AppSpacing.gapLg,
                  ],
                  const _PaymentSection(),
                  AppSpacing.gapLg,
                  const _PreviewBill(),
                  AppSpacing.gapLg,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.textTertiary),
                      AppSpacing.gapSm,
                      Expanded(
                        child: Text(
                          'The final amount is verified by our servers when you place the order.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      bottomNavigationBar: cart.valueOrNull?.isEmpty ?? true
          ? null
          : Container(
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
                        Text(
                          preview.valueOrNull == null
                              ? '—'
                              : Formatters.currency(preview.valueOrNull!.summary.total),
                          style: AppTextStyles.h3,
                        ),
                        Text(checkout.paymentMethod.label, style: AppTextStyles.caption),
                      ],
                    ),
                    AppSpacing.gapLg,
                    Expanded(
                      child: AppButton(
                        label: 'Place Order',
                        isLoading: checkout.isPlacingOrder,
                        // Only once the server has priced this exact order.
                        onPressed: preview.valueOrNull == null || preview.isLoading
                            ? null
                            : () => _placeOrder(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// The bill exactly as the server will charge it.
class _PreviewBill extends ConsumerWidget {
  const _PreviewBill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(checkoutPreviewProvider);
    return preview.when(
      skipLoadingOnReload: true,
      loading: () => const Skeleton(child: SkeletonBox(height: 220, radius: AppRadius.lg)),
      error: (error, _) {
        final isCouponError = error is ApiException && error.fieldErrors.containsKey('coupon_code');
        return AppCard(
          color: AppColors.errorLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ApiException.messageOf(error), style: AppTextStyles.label),
              AppSpacing.gapSm,
              TextButton(
                onPressed: isCouponError
                    ? ref.read(appliedCouponProvider.notifier).remove
                    : () => ref.invalidate(checkoutPreviewProvider),
                child: Text(isCouponError ? 'Remove coupon' : 'Retry'),
              ),
            ],
          ),
        );
      },
      data: (preview) => preview == null
          ? AppCard(
              child: Text(
                'Add a delivery address to see delivery fee and taxes.',
                style: AppTextStyles.bodySmall,
              ),
            )
          : BillSummaryCard(
              summary: preview.summary,
              totalLabel: 'Final amount',
              isUpdating: ref.watch(checkoutPreviewProvider).isLoading,
            ),
    );
  }
}

class _AddressSection extends ConsumerWidget {
  const _AddressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final address = ref.watch(selectedAddressProvider);
    return CheckoutSection(
      step: 1,
      title: 'Delivery address',
      action: address == null
          ? null
          : TextButton(
              onPressed: () => context.push(AppRoutes.location),
              child: const Text('Change'),
            ),
      child: addresses.isLoading && address == null
          ? const Skeleton(child: SkeletonBox(height: 72))
          : address == null
          ? AppButton(
              label: 'Add delivery address',
              icon: Icons.add_location_alt_outlined,
              variant: AppButtonVariant.tonal,
              onPressed: () => context.push(AppRoutes.addAddress),
            )
          : Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(address.label.icon, color: AppColors.primary),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.name,
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(address.displayAddress, style: AppTextStyles.bodySmall),
                          Text(address.phone, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                TextField(
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: ref.read(checkoutProvider.notifier).setInstructions,
                  decoration: const InputDecoration(
                    hintText: 'Delivery instructions (optional)',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    counterText: '',
                  ),
                ),
              ],
            ),
    );
  }
}

class _SlotSection extends ConsumerWidget {
  const _SlotSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(deliverySlotsProvider);
    final selectedId = ref.watch(checkoutProvider.select((s) => s.slotId));
    return CheckoutSection(
      step: 2,
      title: 'Delivery slot',
      child: slots.when(
        loading: () => const Skeleton(
          child: Column(
            children: [
              SkeletonBox(height: 56),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 56),
            ],
          ),
        ),
        error: (error, _) => ErrorView(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(deliverySlotsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Text('Add an address to see delivery slots.', style: AppTextStyles.bodySmall);
          }
          final effective = selectedId ?? list.where((s) => s.isAvailable).firstOrNull?.id;
          return Column(
            children: [
              for (final slot in list) ...[
                SelectableTile(
                  title: slot.label,
                  subtitle: slot.description,
                  icon: slot.isExpress ? Icons.bolt_rounded : Icons.schedule_rounded,
                  badge: slot.isExpress ? 'FASTEST' : null,
                  selected: slot.id == effective,
                  enabled: slot.isAvailable,
                  onTap: () => ref.read(checkoutProvider.notifier).selectSlot(slot.id),
                ),
                AppSpacing.gapSm,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OrderSummarySection extends StatelessWidget {
  const _OrderSummarySection({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return CheckoutSection(
      step: 3,
      title: 'Order summary (${cart.totalQuantity} items)',
      child: Column(
        children: [
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 40,
                    child: AppImage(url: item.product.imageUrl, borderRadius: AppRadius.smAll),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label,
                        ),
                        Text(
                          '${item.product.unit}  ×  ${item.quantity}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(Formatters.currency(item.displayTotal), style: AppTextStyles.label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentSection extends ConsumerWidget {
  const _PaymentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(checkoutProvider.select((s) => s.paymentMethod));
    return CheckoutSection(
      step: AppConfig.couponsEnabled ? 5 : 4,
      title: 'Payment method',
      child: Column(
        children: [
          for (final method in PaymentMethod.available) ...[
            SelectableTile(
              title: method.label,
              subtitle: method.hint,
              icon: method.icon,
              selected: method == selected,
              onTap: () => ref.read(checkoutProvider.notifier).selectPayment(method),
            ),
            AppSpacing.gapSm,
          ],
        ],
      ),
    );
  }
}
