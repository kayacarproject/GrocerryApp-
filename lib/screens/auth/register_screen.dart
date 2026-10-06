import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acceptedTerms = false;
  bool _loading = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      context.showSnack('Please accept the Terms & Privacy Policy', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      context.showSnack('Account created! Please log in to continue.');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) context.go(AppRoutes.login);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _fieldErrors = error.fieldErrors);
      context.showSnack(error.message, isError: true);
    } catch (error) {
      if (mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Sign up in seconds and get 50% off your first order.',
      footer: AuthFooterLink(
        prompt: 'Already have an account?',
        action: 'Log in',
        onTap: () => context.pop(),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                controller: _name,
                hint: 'Your name',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: Validators.name,
                errorText: _fieldErrors['name'],
              ),
              AppSpacing.gapLg,
              AppTextField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                errorText: _fieldErrors['email'],
              ),
              AppSpacing.gapLg,
              AppTextField(
                label: 'Mobile number',
                controller: _phone,
                hint: '10-digit mobile number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.telephoneNumberNational],
                validator: Validators.phone,
                errorText: _fieldErrors['phone'],
              ),
              AppSpacing.gapLg,
              AppTextField(
                label: 'Password',
                controller: _password,
                hint: 'At least 8 characters',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                errorText: _fieldErrors['password'],
              ),
              AppSpacing.gapLg,
              AppTextField(
                label: 'Confirm password',
                controller: _confirm,
                hint: 'Re-enter password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: Validators.confirmPassword(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
              AppSpacing.gapMd,
              InkWell(
                borderRadius: AppRadius.smAll,
                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                child: Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          children: [
                            TextSpan(
                              text: 'Terms',
                              style: AppTextStyles.label.copyWith(color: AppColors.primary),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTextStyles.label.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLg,
              AppButton(label: 'Continue', isLoading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
