import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/product_query.dart';

Future<ProductSort?> showSortSheet(BuildContext context, ProductSort current) =>
    showModalBottomSheet<ProductSort>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.screen,
              child: Text('Sort by', style: AppTextStyles.h2),
            ),
            AppSpacing.gapSm,
            for (final sort in ProductSort.values)
              ListTile(
                contentPadding: AppSpacing.screen,
                title: Text(
                  sort.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: sort == current ? FontWeight.w700 : FontWeight.w500,
                    color: sort == current ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: sort == current
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : const Icon(Icons.circle_outlined, color: AppColors.border),
                selected: sort == current,
                onTap: () => Navigator.of(context).pop(sort),
              ),
            AppSpacing.gapSm,
          ],
        ),
      ),
    );
