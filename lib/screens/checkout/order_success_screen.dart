import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/order/payment_method_style.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: order.when(
            loading: () => const ListSkeleton(count: 2, item: TileSkeleton()),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
            ),
            data: (order) => _Content(order: order),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.order});

  final Order order;

  String get _eta {
    final estimated = order.delivery.estimatedAt;
    if (estimated != null) {
      final minutes = estimated.difference(DateTime.now()).inMinutes.clamp(1, 999);
      return 'Arriving in ~$minutes mins (by ${Formatters.time(estimated)})';
    }
    return order.delivery.slot?.label ?? 'We\'ll update you shortly';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const _AnimatedCheck(),
                AppSpacing.gapXxl,
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Order Placed Successfully',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h1,
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  'Sit back and relax, we\'re getting your groceries ready.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.gapXxl,
                AppCard(
                  borderColor: AppColors.border,
                  child: Column(
                    children: [
                      _Row(label: 'Order ID', value: '#${order.orderNumber}'),
                      _Row(label: 'Estimated delivery', value: _eta),
                      _Row(label: 'Payment', value: '${order.payment.method.label} · ${order.payment.status.label}'),
                      const Divider(height: AppSpacing.xl),
                      _Row(
                        label: 'Total amount',
                        value: Formatters.currency(order.summary.total),
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AppButton(
                label: 'Track Order',
                icon: Icons.location_on_outlined,
                onPressed: () => context.pushReplacement(AppRoutes.orderTracking(order.id)),
              ),
              AppSpacing.gapMd,
              AppButton(
                label: 'Continue Shopping',
                variant: AppButtonVariant.outline,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? AppTextStyles.title
                  : AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          AppSpacing.gapMd,
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasize ? AppTextStyles.h3 : AppTextStyles.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (context, value, _) => Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primarySoft, width: 10),
            ),
            child: const Icon(Icons.check_rounded, size: 64, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
