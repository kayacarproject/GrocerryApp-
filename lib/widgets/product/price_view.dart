import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Selling price with the struck-through MRP when discounted.
class PriceView extends StatelessWidget {
  const PriceView({
    super.key,
    required this.price,
    required this.mrp,
    this.large = false,
    this.axis = Axis.vertical,
  });

  final double price;
  final double mrp;
  final bool large;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = mrp > price;
    final priceText = Text(
      Formatters.currency(price),
      style: large ? AppTextStyles.h2 : AppTextStyles.price,
    );
    final mrpText = hasDiscount
        ? Text(
            Formatters.currency(mrp),
            style: large
                ? AppTextStyles.strikePrice.copyWith(fontSize: 14)
                : AppTextStyles.strikePrice,
          )
        : null;

    return Semantics(
      label: hasDiscount
          ? 'Price ${Formatters.currency(price)}, was ${Formatters.currency(mrp)}'
          : 'Price ${Formatters.currency(price)}',
      excludeSemantics: true,
      child: axis == Axis.vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [priceText, ?mrpText],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                priceText,
                if (mrpText != null) ...[AppSpacing.gapSm, mrpText],
              ],
            ),
    );
  }
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, this.large = false});

  final int percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AppSpacing.sm : 6,
        vertical: large ? AppSpacing.xs : 3,
      ),
      decoration: const BoxDecoration(
        color: AppColors.discount,
        borderRadius: AppRadius.xsAll,
      ),
      child: Text(
        '$percent% OFF',
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: large ? 12 : 10,
        ),
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.reviewCount});

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} out of 5'
          '${reviewCount == null ? '' : ' from $reviewCount reviews'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.rating,
              borderRadius: AppRadius.xsAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.star_rounded, size: 12, color: Colors.white),
              ],
            ),
          ),
          if (reviewCount != null) ...[
            AppSpacing.gapXs,
            Text(
              '(${Formatters.compactCount(reviewCount!)})',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}
