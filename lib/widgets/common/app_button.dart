import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

enum AppButtonVariant { primary, outline, tonal, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.height = AppSizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final foreground = variant == AppButtonVariant.primary
        ? AppColors.textOnPrimary
        : AppColors.primary;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foreground,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final size = Size(expand ? double.infinity : 64, height);
    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: size,
          // Keep the brand colour while showing the spinner.
          disabledBackgroundColor: isLoading ? AppColors.primary : null,
        ),
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(minimumSize: size),
        child: child,
      ),
      AppButtonVariant.tonal => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: size,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
        ),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(minimumSize: size),
        child: child,
      ),
    };

    return Semantics(
      label: isLoading ? '$label, please wait' : null,
      child: button,
    );
  }
}
