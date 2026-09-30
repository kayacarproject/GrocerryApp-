import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import 'order_status_chip.dart';

/// Vertical Placed → Confirmed → Preparing → Out for Delivery → Delivered.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final Order order;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static const _descriptions = {
    OrderStatus.pending: 'We have received your order',
    OrderStatus.confirmed: 'The store has accepted your order',
    OrderStatus.preparing: 'Your items are being packed',
    OrderStatus.outForDelivery: 'Your order is on the way',
    OrderStatus.delivered: 'Enjoy your groceries!',
  };

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order cancelled', style: AppTextStyles.title),
                if (order.timeOf(OrderStatus.cancelled) case final at?)
                  Text(Formatters.dateTime(at), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      );
    }

    final current = order.status.step;
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          _TimelineStep(
            status: _steps[i],
            description: _descriptions[_steps[i]]!,
            time: order.timeOf(_steps[i]),
            isDone: i <= current,
            isCurrent: i == current,
            isLast: i == _steps.length - 1,
            nextDone: i + 1 <= current,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.description,
    required this.time,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.nextDone,
  });

  final OrderStatus status;
  final String description;
  final DateTime? time;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final bool nextDone;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.primary : AppColors.border;
    return Semantics(
      label: '${status.timelineLabel}, ${isDone ? 'completed' : 'pending'}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isCurrent ? 32 : 26,
                    height: isCurrent ? 32 : 26,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isDone && !isCurrent ? Icons.check_rounded : status.icon,
                      size: isCurrent ? 18 : 14,
                      color: isDone ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 2.5,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: nextDone ? AppColors.primary : AppColors.border,
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl, top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status.timelineLabel,
                            style: AppTextStyles.title.copyWith(
                              color: isDone ? AppColors.textPrimary : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        if (time != null && isDone)
                          Text(Formatters.time(time!), style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDone ? AppColors.textSecondary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
