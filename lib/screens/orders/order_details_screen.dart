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
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/cart/bill_summary_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_image.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/order/order_status_chip.dart';
import '../../widgets/order/payment_method_style.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel this order?',
      message: 'Any online payment will be refunded to the original payment method.',
      confirmLabel: 'Cancel order',
      cancelLabel: 'Keep order',
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(orderActionsProvider).cancel(widget.orderId);
      if (mounted) context.showSnack('Your order has been cancelled');
    } catch (error) {
      if (mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: order.when(
        loading: () => const ListSkeleton(count: 3),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (order) => RefreshIndicator(
          onRefresh: () => ref.refresh(orderDetailProvider(widget.orderId).future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _StatusCard(order: order),
              AppSpacing.gapLg,
              _ItemsCard(order: order),
              AppSpacing.gapLg,
              BillSummaryCard(summary: order.summary, totalLabel: 'Total paid'),
              AppSpacing.gapLg,
              _InfoCard(order: order),
              if (AppConfig.supportPagesEnabled) ...[
                AppSpacing.gapLg,
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.info(InfoPage.help)),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Need help with this order?'),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: order.valueOrNull == null
          ? null
          : _Actions(
              order: order.valueOrNull!,
              cancelling: _cancelling,
              onCancel: _cancel,
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: order.status.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(order.status.icon, color: order.status.color),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.orderNumber}', style: AppTextStyles.title),
                Text('Placed on ${Formatters.dateTime(order.createdAt)}', style: AppTextStyles.bodySmall),
                AppSpacing.gapSm,
                OrderStatusChip(status: order.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${order.itemCount} items in this order', style: AppTextStyles.title),
          AppSpacing.gapMd,
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: InkWell(
                onTap: () => context.push(AppRoutes.product(item.productId)),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      child: AppImage(url: item.imageUrl, borderRadius: AppRadius.smAll),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.label),
                          Text(
                            '${item.unit} · ${Formatters.currency(item.price)} × ${item.quantity}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    Text(Formatters.currency(item.total), style: AppTextStyles.label),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    Widget section(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xxs),
                Text(body, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );

    return AppCard(
      child: Column(
        children: [
          section(
            Icons.location_on_outlined,
            'Delivery address · ${order.address.name}',
            '${order.address.displayAddress}\n${order.address.phone}',
          ),
          const Divider(),
          section(
            order.payment.method.icon,
            'Payment',
            [
              order.payment.method.label,
              order.payment.status.label,
              if (order.payment.transactionId != null) 'Ref: ${order.payment.transactionId}',
            ].join(' · '),
          ),
          if (order.delivery.slot != null) ...[
            const Divider(),
            section(Icons.schedule_rounded, 'Delivery slot', order.delivery.slot!.label),
          ],
          if (order.couponCode != null) ...[
            const Divider(),
            section(Icons.local_offer_outlined, 'Coupon applied', order.couponCode!),
          ],
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.order, required this.cancelling, required this.onCancel});

  final Order order;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsPayment =
        AppConfig.onlinePaymentsEnabled && ref.read(orderActionsProvider).needsPayment(order);
    final buttons = <Widget>[
      if (order.isCancellable)
        Expanded(
          child: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outline,
            isLoading: cancelling,
            onPressed: onCancel,
          ),
        ),
      if (needsPayment)
        Expanded(
          child: AppButton(
            label: 'Complete payment',
            onPressed: () => context.push(AppRoutes.payment(order.id)),
          ),
        )
      else if (order.status.isActive)
        Expanded(
          child: AppButton(
            label: 'Track order',
            icon: Icons.location_on_outlined,
            onPressed: () => context.push(AppRoutes.orderTracking(order.id)),
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) AppSpacing.gapMd,
              buttons[i],
            ],
          ],
        ),
      ),
    );
  }
}
