import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

extension BuildContextX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  TextTheme get textTheme => Theme.of(this).textTheme;

  void showSnack(
    String message, {
    bool isError = false,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
          action: action,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void unfocus() => FocusScope.of(this).unfocus();
}

extension StringX on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get initials {
    final parts = trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}
