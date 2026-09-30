import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../models/product.dart';
import '../common/section_header.dart';
import 'product_card.dart';

/// Titled horizontal list of product cards.
class ProductRail extends StatelessWidget {
  const ProductRail({
    super.key,
    required this.title,
    required this.products,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final List<Product> products;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final cardWidth = AppSizes.railCardWidth(MediaQuery.sizeOf(context).width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle, onAction: onSeeAll),
        AppSpacing.gapMd,
        SizedBox(
          height: AppSizes.productCardHeight(context, cardWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screen,
            itemCount: products.length,
            separatorBuilder: (_, _) => AppSpacing.gapMd,
            itemBuilder: (_, index) => SizedBox(
              width: cardWidth,
              child: ProductCard(product: products[index]),
            ),
          ),
        ),
      ],
    );
  }
}
