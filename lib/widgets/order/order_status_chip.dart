import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/order.dart';

extension OrderStatusStyle on OrderStatus {
  Color get color => switch (this) {
    // Darker amber keeps text readable on the tinted chip background.
    OrderStatus.pending => const Color(0xFFB45309),
    OrderStatus.confirmed => AppColors.info,
    OrderStatus.preparing => const Color(0xFF7C3AED),
    OrderStatus.outForDelivery => const Color(0xFFEA580C),
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.error,
  };

  IconData get icon => switch (this) {
    OrderStatus.pending => Icons.receipt_long_rounded,
    OrderStatus.confirmed => Icons.thumb_up_alt_rounded,
    OrderStatus.preparing => Icons.inventory_2_rounded,
    OrderStatus.outForDelivery => Icons.delivery_dining_rounded,
    OrderStatus.delivered => Icons.check_circle_rounded,
    OrderStatus.cancelled => Icons.cancel_rounded,
  };

  /// Label used on the tracking timeline.
  String get timelineLabel => switch (this) {
    OrderStatus.pending => 'Order Placed',
    OrderStatus.confirmed => 'Order Confirmed',
    _ => label,
  };
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: AppTextStyles.caption.copyWith(
              color: status.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
