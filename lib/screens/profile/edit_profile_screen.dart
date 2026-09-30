import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _user = ref.read(currentUserProvider);
  late final _name = TextEditingController(text: _user?.name);
  late final _email = TextEditingController(text: _user?.email);
  late final _phone = TextEditingController(text: _user?.phone);
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    context.unfocus();
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileControllerProvider).updateProfile(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
      );
      if (!mounted) return;
      context.showSnack('Profile updated');
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _fieldErrors = error.fieldErrors);
      context.showSnack(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _name.text.initials,
                  style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                ),
              ),
            ),
            AppSpacing.gapXxl,
            AppTextField(
              label: 'Full name',
              controller: _name,
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: Validators.name,
              errorText: _fieldErrors['name'],
            ),
            AppSpacing.gapLg,
            AppTextField(
              label: 'Email',
              controller: _email,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              errorText: _fieldErrors['email'],
            ),
            AppSpacing.gapLg,
            AppTextField(
              label: 'Mobile number',
              controller: _phone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              validator: Validators.phone,
              errorText: _fieldErrors['phone'],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
        ),
      ),
    );
  }
}
