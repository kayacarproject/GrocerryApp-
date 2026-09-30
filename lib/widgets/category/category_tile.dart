import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../models/category.dart';
import '../common/app_image.dart';

/// Compact category tile for the home screen grid.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => context.push(AppRoutes.category(category.id)),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AppImage(
                url: category.imageUrl,
                borderRadius: AppRadius.lgAll,
                background: AppColors.fromHex(category.colorHex),
                emojiScale: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Larger card used on the Categories tab.
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.fromHex(category.colorHex);
    return Semantics(
      button: true,
      label: '${category.name}, ${category.productCount} products',
      excludeSemantics: true,
      child: Material(
        color: tint,
        borderRadius: AppRadius.lgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.category(category.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label,
                ),
                if (category.productCount > 0)
                  Text(
                    '${category.productCount} items',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      heightFactor: 0.9,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AppImage(
                          url: category.imageUrl,
                          borderRadius: AppRadius.mdAll,
                          background: Colors.transparent,
                          emojiScale: 0.85,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
