import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import 'empty_state_view.dart';

/// Friendly error with retry. Uses a network-specific illustration when the
/// failure was connectivity related. Raw error details are never shown.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;

  /// Inline variant for use inside lists and sections.
  final bool compact;

  bool get _isNetwork {
    final e = error;
    return e is ApiException && e.isNetworkError;
  }

  @override
  Widget build(BuildContext context) {
    final message = ApiException.messageOf(error);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              _isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              color: AppColors.textSecondary,
            ),
            AppSpacing.gapMd,
            Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    return EmptyStateView(
      icon: _isNetwork ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      accent: _isNetwork ? AppColors.info : AppColors.error,
      title: _isNetwork ? 'You\'re offline' : 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}
