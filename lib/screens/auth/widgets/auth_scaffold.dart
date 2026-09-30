import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Shared layout for authentication screens: title block, scrollable form
/// and an optional footer, all keyboard safe.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.header,
    this.footer,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? header;
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header != null) ...[header!, AppSpacing.gapXxl],
                Semantics(header: true, child: Text(title, style: AppTextStyles.h1)),
                AppSpacing.gapSm,
                Text(
                  subtitle,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                child,
                if (footer != null) ...[AppSpacing.gapXxl, Center(child: footer!)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Question? Action" footer link.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}
