import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle get _base =>
      GoogleFonts.plusJakartaSans(color: AppColors.textPrimary);

  static TextStyle get display =>
      _base.copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.2);
  static TextStyle get h1 =>
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25);
  static TextStyle get h2 =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get h3 =>
      _base.copyWith(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get title =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, height: 1.35);
  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5);
  static TextStyle get body =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45);
  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  static TextStyle get caption => _base.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textTertiary,
  );
  static TextStyle get label =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get button =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2);
  static TextStyle get price =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2);
  static TextStyle get strikePrice => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.textTertiary,
  );

  static TextTheme get textTheme => TextTheme(
    displaySmall: display,
    headlineMedium: h1,
    headlineSmall: h2,
    titleLarge: h3,
    titleMedium: title,
    titleSmall: label,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: button,
    labelMedium: label,
    labelSmall: caption,
  );
}
