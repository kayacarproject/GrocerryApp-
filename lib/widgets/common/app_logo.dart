import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Basketly brand mark: a rounded basket badge plus wordmark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56, this.onDark = false, this.showName = true});

  final double size;
  final bool onDark;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shopping_basket_rounded,
            size: size * 0.58,
            color: onDark ? AppColors.primary : Colors.white,
          ),
          Positioned(
            top: size * 0.14,
            right: size * 0.16,
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showName) return Semantics(label: AppConfig.appName, child: badge);

    return Semantics(
      label: AppConfig.appName,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          SizedBox(height: size * 0.28),
          Text(
            AppConfig.appName.toLowerCase(),
            style: AppTextStyles.display.copyWith(
              fontSize: size * 0.55,
              letterSpacing: -0.5,
              color: onDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
