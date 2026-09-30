import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(email: _identifier.text, password: _password.text);
      // Router redirects to home once authenticated.
    } catch (error) {
      if (mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo() {
    _identifier.text = AppConfig.useMockData ? AppStrings.demoEmail : AppStrings.devApiEmail;
    _password.text = AppConfig.useMockData ? AppStrings.demoPassword : AppStrings.devApiPassword;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: false,
      header: const AppLogo(size: 48, showName: false),
      title: 'Welcome back 👋',
      subtitle: 'Log in to continue shopping fresh groceries.',
      footer: AuthFooterLink(
        prompt: 'New to ${AppConfig.appName}?',
        action: 'Create account',
        onTap: () => context.push(AppRoutes.register),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Email',
                controller: _identifier,
                hint: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              AppSpacing.gapLg,
              AppTextField(
                label: 'Password',
                controller: _password,
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.loginPassword,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              AppSpacing.gapSm,
              AppButton(label: 'Log in', isLoading: _loading, onPressed: _submit),
              if (AppConfig.isDevelopment) ...[
                AppSpacing.gapXl,
                _DemoCredentials(onFill: _fillDemo),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials({required this.onFill});

  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Color(0xFF92400E)),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.useMockData ? 'Demo mode' : 'Test account (dev server)',
                  style: AppTextStyles.label,
                ),
                Text(
                  AppConfig.useMockData
                      ? '${AppStrings.demoEmail}\n${AppStrings.demoPassword}  ·  OTP ${AppStrings.demoOtp}'
                      : '${AppStrings.devApiEmail}\n${AppStrings.devApiPassword}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onFill, child: const Text('Fill')),
        ],
      ),
    );
  }
}
