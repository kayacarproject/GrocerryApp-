import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../common/app_card.dart';
import '../common/app_image.dart';
import 'order_status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    const maxThumbs = 4;
    final extra = order.items.length - maxThumbs;
    return AppCard(
      onTap: () => context.push(AppRoutes.orderDetail(order.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.orderNumber}', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      Formatters.dateTime(order.createdAt),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              for (final item in order.items.take(maxThumbs))
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: SizedBox.square(
                    dimension: 46,
                    child: AppImage(
                      url: item.imageUrl,
                      borderRadius: AppRadius.smAll,
                      semanticLabel: item.name,
                    ),
                  ),
                ),
              if (extra > 0)
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text('+$extra', style: AppTextStyles.label),
                ),
            ],
          ),
          AppSpacing.gapMd,
          const Divider(),
          AppSpacing.gapSm,
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}'
                  ' · ${Formatters.currency(order.summary.total)}',
                  style: AppTextStyles.label,
                ),
              ),
              if (order.status.isActive)
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.orderTracking(order.id)),
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('Track'),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}
