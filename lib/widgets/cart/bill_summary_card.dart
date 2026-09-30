import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/price_summary.dart';
import '../common/app_card.dart';

/// Server-computed bill breakdown for carts and orders.
class BillSummaryCard extends StatelessWidget {
  const BillSummaryCard({
    super.key,
    required this.summary,
    this.title = 'Bill details',
    this.totalLabel = 'To pay',
    this.isUpdating = false,
  });

  final PriceSummary summary;
  final String title;
  final String totalLabel;

  /// Dims the numbers while the server is re-pricing.
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final freeDelivery = summary.deliveryFee == 0 && summary.subtotal > 0;
    return AppCard(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isUpdating ? 0.5 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            AppSpacing.gapMd,
            _Row(label: 'Items total (MRP)', value: Formatters.currency(summary.itemsMrp)),
            if (summary.productDiscount > 0)
              _Row(
                label: 'Product discount',
                value: '- ${Formatters.currency(summary.productDiscount)}',
                valueColor: AppColors.success,
              ),
            if (summary.couponDiscount > 0)
              _Row(
                label: 'Coupon discount',
                value: '- ${Formatters.currency(summary.couponDiscount)}',
                valueColor: AppColors.success,
              ),
            if (summary.includesCharges) ...[
              _Row(
                label: 'Delivery fee',
                value: freeDelivery ? 'FREE' : Formatters.currency(summary.deliveryFee),
                valueColor: freeDelivery ? AppColors.success : null,
              ),
              _Row(label: 'Taxes', value: Formatters.currency(summary.tax)),
            ] else
              const _Row(label: 'Delivery fee & taxes', value: 'At checkout'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(child: Text(totalLabel, style: AppTextStyles.h3)),
                Text(Formatters.currency(summary.total), style: AppTextStyles.h3),
              ],
            ),
            if (summary.totalSavings > 0) ...[
              AppSpacing.gapMd,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  'You save ${Formatters.currency(summary.totalSavings)} on this order 🎉',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
