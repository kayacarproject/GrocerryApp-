import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../models/product.dart';
import 'product_card.dart';

/// Responsive product grid (2 columns on phones, 3 on wider screens).
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent + AppSpacing.lg * 2;
          return SliverGrid.builder(
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppSizes.gridColumns(width),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: AppSizes.productCardHeight(
                context,
                AppSizes.gridCellWidth(width),
              ),
            ),
            itemBuilder: (_, index) => ProductCard(product: products[index]),
          );
        },
      ),
    );
  }
}
