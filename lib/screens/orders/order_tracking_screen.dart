import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/launcher.dart';
import '../../models/delivery.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/order/order_status_chip.dart';
import '../../widgets/order/order_timeline.dart';

/// Live order status. Polls the server while the order is in progress.
class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(orderTrackingProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track order'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.orderDetail(orderId)),
            child: const Text('Details'),
          ),
        ],
      ),
      body: tracking.when(
        skipLoadingOnRefresh: true,
        loading: () => const ListSkeleton(count: 3),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(orderTrackingProvider(orderId)),
        ),
        data: (order) => RefreshIndicator(
          onRefresh: () => ref.refresh(orderTrackingProvider(orderId).future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _HeroCard(order: order),
              AppSpacing.gapLg,
              if (order.delivery.partner != null && order.status.isActive) ...[
                _PartnerCard(partner: order.delivery.partner!),
                AppSpacing.gapLg,
              ],
              AppCard(child: OrderTimeline(order: order)),
              AppSpacing.gapLg,
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivering to ${order.address.name}', style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(order.address.displayAddress, style: AppTextStyles.bodySmall),
                        ],
                      ),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.order});

  final Order order;

  String get _headline => switch (order.status) {
    OrderStatus.pending => 'Order received',
    OrderStatus.confirmed => 'Order confirmed',
    OrderStatus.preparing => 'Packing your order',
    OrderStatus.outForDelivery => 'On the way to you',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Order cancelled',
  };

  String get _eta {
    if (order.status == OrderStatus.delivered) {
      final at = order.delivery.deliveredAt;
      return at == null ? 'Delivered' : 'Delivered at ${Formatters.time(at)}';
    }
    if (order.status == OrderStatus.cancelled) return 'This order will not be delivered';
    final estimated = order.delivery.estimatedAt;
    if (estimated != null) {
      final minutes = estimated.difference(DateTime.now()).inMinutes;
      return minutes > 0
          ? 'Arriving in ~$minutes mins · by ${Formatters.time(estimated)}'
          : 'Arriving any minute now';
    }
    return order.delivery.slot?.label ?? 'We\'ll keep you posted';
  }

  @override
  Widget build(BuildContext context) {
    final color = order.status.color;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        color: color,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                  AppSpacing.gapXs,
                  Text(_headline, style: AppTextStyles.h2.copyWith(color: Colors.white)),
                  AppSpacing.gapXs,
                  Text(_eta, style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
                ],
              ),
            ),
            _PulsingIcon(icon: order.status.icon, active: order.status.isActive),
          ],
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, color: Colors.white, size: 34),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partner});

  final DeliveryPartner partner;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accentLight,
            child: Icon(Icons.delivery_dining_rounded, color: Color(0xFF92400E)),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner.name, style: AppTextStyles.title),
                Text(
                  [
                    'Your delivery partner',
                    if (partner.rating != null) '★ ${partner.rating!.toStringAsFixed(1)}',
                  ].join(' · '),
                  style: AppTextStyles.bodySmall,
                ),
                if (partner.vehicleNumber != null)
                  Text(partner.vehicleNumber!, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Call ${partner.name}',
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Launcher.call(context, partner.phone),
            icon: const Icon(Icons.call_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
