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
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/address_card.dart';

/// Add a new address, or edit [initial] when provided.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.initial});

  final Address? initial;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullAddress;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _phone;
  late final TextEditingController _customName;
  late AddressLabel _label;
  late bool _isDefault;
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _fullAddress = TextEditingController(text: a?.fullAddress);
    _city = TextEditingController(text: a?.city);
    _state = TextEditingController(text: a?.state);
    _pincode = TextEditingController(text: a?.pincode);
    _phone = TextEditingController(text: a?.phone ?? ref.read(currentUserProvider)?.phone);
    _label = a?.label ?? AddressLabel.home;
    _customName = TextEditingController(text: _label == AddressLabel.other ? a?.name : '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final c in [_fullAddress, _city, _state, _pincode, _phone, _customName]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _name => _label == AddressLabel.other && _customName.text.trim().isNotEmpty
      ? _customName.text.trim()
      : _label.display;

  Future<void> _save() async {
    context.unfocus();
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final address = Address(
      id: widget.initial?.id ?? '',
      name: _name,
      fullAddress: _fullAddress.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
      phone: _phone.text.trim(),
      isDefault: _isDefault,
      latitude: widget.initial?.latitude,
      longitude: widget.initial?.longitude,
    );

    try {
      final notifier = ref.read(addressesProvider.notifier);
      if (_isEditing) {
        await notifier.edit(address);
      } else {
        final created = await notifier.add(address);
        // A newly added address becomes the delivery location.
        ref.read(selectedAddressIdProvider.notifier).select(created.id);
      }
      if (!mounted) return;
      context.showSnack(_isEditing ? 'Address updated' : 'Address saved');
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit address' : 'Add new address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text('Save address as', style: AppTextStyles.label),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final label in AddressLabel.values)
                  ChoiceChip(
                    avatar: Icon(
                      label.icon,
                      size: 18,
                      color: _label == label ? AppColors.primary : AppColors.textSecondary,
                    ),
                    label: Text(label.display),
                    selected: _label == label,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _label = label),
                  ),
              ],
            ),
            if (_label == AddressLabel.other) ...[
              AppSpacing.gapLg,
              AppTextField(
                label: 'Address name',
                controller: _customName,
                hint: 'e.g. Mom\'s place',
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(v, 'Address name'),
              ),
            ],
            AppSpacing.gapXl,
            AppTextField(
              label: 'Full address',
              controller: _fullAddress,
              hint: 'House / flat no., building, street, area',
              maxLines: 3,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Address'),
              errorText: _fieldErrors['full_address'],
            ),
            AppSpacing.gapLg,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'City',
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, 'City'),
                    errorText: _fieldErrors['city'],
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: AppTextField(
                    label: 'Pincode',
                    controller: _pincode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofillHints: const [AutofillHints.postalCode],
                    validator: Validators.pincode,
                    errorText: _fieldErrors['pincode'],
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,
            AppTextField(
              label: 'State',
              controller: _state,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'State'),
              errorText: _fieldErrors['state'],
            ),
            AppSpacing.gapLg,
            AppTextField(
              label: 'Phone number for delivery',
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              validator: Validators.phone,
              errorText: _fieldErrors['phone'],
            ),
            if (!(widget.initial?.isDefault ?? false)) ...[
              AppSpacing.gapMd,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Make this my default address', style: AppTextStyles.body),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: AppButton(
            label: _isEditing ? 'Update address' : 'Save address',
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
