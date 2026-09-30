import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';

/// Numbered checkout step card.
class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.step,
    required this.title,
    required this.child,
    this.action,
  });

  final int step;
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: AppTextStyles.title),
                ),
              ),
              ?action,
            ],
          ),
          AppSpacing.gapMd,
          child,
        ],
      ),
    );
  }
}

/// Selectable row used for delivery slots and payment methods.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.enabled = true,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? AppColors.textPrimary : AppColors.textTertiary;
    return Semantics(
      selected: selected,
      enabled: enabled,
      button: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.mdAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
                AppSpacing.gapMd,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title, style: AppTextStyles.label.copyWith(color: fg)),
                        ),
                        if (badge != null) ...[
                          AppSpacing.gapSm,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Text(
                              badge!,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF92400E),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
