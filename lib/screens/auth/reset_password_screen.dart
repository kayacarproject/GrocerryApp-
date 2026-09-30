import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/validators.dart';
import '../../models/auth_session.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.ticket});

  final PasswordResetTicket ticket;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).resetPassword(widget.ticket, _password.text);
      if (!mounted) return;
      context.showSnack('Password updated. Please log in.');
      context.go(AppRoutes.login);
    } catch (error) {
      if (mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set a new password',
      subtitle: 'Choose a strong password you haven\'t used before.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'New password',
                controller: _password,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm new password',
                controller: _confirm,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: Validators.confirmPassword(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              AppButton(label: 'Update password', isLoading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
