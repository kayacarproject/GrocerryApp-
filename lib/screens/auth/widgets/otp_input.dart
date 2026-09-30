import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Six digit boxes backed by one hidden text field, so paste and SMS
/// autofill (`oneTimeCode`) work naturally.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool hasError;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return Semantics(
      label: 'Verification code, ${code.length} of ${widget.length} digits entered',
      textField: true,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: _box(i, code)),
              ],
            ],
          ),
          // Invisible input stretched over the boxes to capture taps and keys.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(int index, String code) {
    final filled = index < code.length;
    final active = _focusNode.hasFocus && index == code.length.clamp(0, widget.length - 1);
    final borderColor = widget.hasError
        ? AppColors.error
        : active
        ? AppColors.primary
        : filled
        ? AppColors.primarySoft
        : AppColors.border;
    return AspectRatio(
      aspectRatio: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryLight : AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: borderColor, width: active ? 1.8 : 1.2),
        ),
        child: Text(filled ? code[index] : '', style: AppTextStyles.h2),
      ),
    );
  }
}
