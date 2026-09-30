import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/auth_session.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/otp_input.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.challenge});

  final OtpChallenge challenge;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const _length = 6;

  late OtpChallenge _challenge = widget.challenge;
  final _code = TextEditingController();
  Timer? _timer;
  late int _secondsLeft;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  String get _maskedTarget => Validators.isEmail(_challenge.target)
      ? _challenge.target
      : '+91 ${Formatters.maskPhone(_challenge.target)}';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _challenge.resendAfterSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (_verifying) return;
    if (_code.text.length != _length) {
      setState(() => _error = 'Enter the $_length-digit code');
      return;
    }
    context.unfocus();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authProvider.notifier)
          .verifyOtp(_challenge, _code.text);
      if (!mounted) return;
      if (result.resetToken != null) {
        context.pushReplacement(
          AppRoutes.resetPassword,
          extra: PasswordResetTicket(email: _challenge.target, token: result.resetToken!),
        );
      }
      // Registration: auth state changes and the router moves to home.
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiException.messageOf(error));
        _code.clear();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final next = await ref.read(authProvider.notifier).resendOtp(_challenge);
      if (mounted) setState(() => _challenge = next);
      if (!mounted) return;
      _startTimer();
      context.showSnack('A new code has been sent');
    } catch (error) {
      if (mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify it\'s you',
      subtitle: 'Enter the $_length-digit code sent to $_maskedTarget',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OtpInput(
            controller: _code,
            length: _length,
            hasError: _error != null,
            onCompleted: (_) => _verify(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _error == null
                ? const SizedBox(height: AppSpacing.md)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
          ),
          if (AppConfig.isDevelopment && _challenge.debugCode != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text('Dev code: ${_challenge.debugCode}', style: AppTextStyles.caption),
            ),
          AppSpacing.gapXl,
          AppButton(label: 'Verify', isLoading: _verifying, onPressed: _verify),
          AppSpacing.gapLg,
          Center(
            child: _secondsLeft > 0
                ? Text(
                    'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodySmall,
                  )
                : TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_resending ? 'Sending…' : 'Resend code'),
                  ),
          ),
        ],
      ),
    );
  }
}
