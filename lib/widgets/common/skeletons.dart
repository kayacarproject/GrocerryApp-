import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Wraps skeleton shapes in a single shimmer sweep.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: Shimmer.fromColors(
      baseColor: const Color(0xFFECEEF1),
      highlightColor: const Color(0xFFF8F9FA),
      period: const Duration(milliseconds: 1300),
      child: child,
    ),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFECEEF1),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 1, child: SkeletonBox(radius: AppRadius.md)),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 12, width: 60),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 14),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(height: 14, width: 90),
        Spacer(),
        Row(
          children: [
            SkeletonBox(height: 18, width: 50),
            Spacer(),
            SkeletonBox(height: 32, width: 64),
          ],
        ),
      ],
    ),
  );
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Skeleton(
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppSizes.gridColumns(width),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: AppSizes.productCardHeight(
            context,
            AppSizes.gridCellWidth(width),
          ),
        ),
        itemBuilder: (_, _) => const ProductSkeleton(),
      ),
    );
  }
}

class ProductRailSkeleton extends StatelessWidget {
  const ProductRailSkeleton({super.key, required this.cardWidth});

  final double cardWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.productCardHeight(context, cardWidth),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: AppSpacing.screen,
      itemCount: 3,
      separatorBuilder: (_, _) => AppSpacing.gapMd,
      itemBuilder: (_, _) =>
          SizedBox(width: cardWidth, child: const ProductSkeleton()),
    ),
  );
}

class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AspectRatio(aspectRatio: 1, child: SkeletonBox(radius: AppRadius.lg)),
      SizedBox(height: AppSpacing.sm),
      SkeletonBox(height: 10, width: 56),
    ],
  );
}

class CategoryGridSkeleton extends StatelessWidget {
  const CategoryGridSkeleton({super.key, this.count = 8, this.columns = 4});

  final int count;
  final int columns;

  @override
  Widget build(BuildContext context) => Skeleton(
    child: GridView.builder(
      padding: AppSpacing.screen,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, _) => const CategorySkeleton(),
    ),
  );
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardWidth = AppSizes.railCardWidth(MediaQuery.sizeOf(context).width);
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: AppSpacing.screen,
            child: AspectRatio(
              aspectRatio: 2.2,
              child: SkeletonBox(radius: AppRadius.xl),
            ),
          ),
          AppSpacing.gapXl,
          const Padding(
            padding: AppSpacing.screen,
            child: SkeletonBox(height: 18, width: 140),
          ),
          AppSpacing.gapMd,
          const CategoryGridSkeleton(count: 8),
          AppSpacing.gapXl,
          const Padding(
            padding: AppSpacing.screen,
            child: SkeletonBox(height: 18, width: 120),
          ),
          AppSpacing.gapMd,
          ProductRailSkeleton(cardWidth: cardWidth),
        ],
      ),
    );
  }
}

class OrderSkeleton extends StatelessWidget {
  const OrderSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonBox(height: 16, width: 120),
            Spacer(),
            SkeletonBox(height: 22, width: 80, radius: AppRadius.pill),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 12, width: 160),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            SkeletonBox(height: 44, width: 44),
            SizedBox(width: AppSpacing.sm),
            SkeletonBox(height: 44, width: 44),
            SizedBox(width: AppSpacing.sm),
            SkeletonBox(height: 44, width: 44),
          ],
        ),
      ],
    ),
  );
}

/// Generic skeleton list for orders, addresses or notifications.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 4, this.item});

  final int count;
  final Widget? item;

  @override
  Widget build(BuildContext context) => Skeleton(
    child: ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => AppSpacing.gapMd,
      itemBuilder: (_, _) => item ?? const OrderSkeleton(),
    ),
  );
}

class TileSkeleton extends StatelessWidget {
  const TileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
    ),
    child: const Row(
      children: [
        SkeletonBox(height: 44, width: 44, radius: AppRadius.pill),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 14, width: 140),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(height: 12),
            ],
          ),
        ),
      ],
    ),
  );
}
