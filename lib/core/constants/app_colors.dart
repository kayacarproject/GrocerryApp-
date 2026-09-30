import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0E7C4A);
  static const Color primaryDark = Color(0xFF09603A);
  static const Color primaryLight = Color(0xFFE7F5EE);
  static const Color primarySoft = Color(0xFFCDEBDC);
  static const Color accent = Color(0xFFFFB020);
  static const Color accentLight = Color(0xFFFFF4DC);

  // Surfaces
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F3F5);
  static const Color border = Color(0xFFE6E8EC);
  static const Color divider = Color(0xFFEEF0F3);

  // Text
  static const Color textPrimary = Color(0xFF14181F);
  static const Color textSecondary = Color(0xFF5B6472);
  static const Color textTertiary = Color(0xFF8D96A3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFD92D20);
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFE8F0FE);
  static const Color discount = Color(0xFF2D6CDF);
  static const Color rating = Color(0xFF1C8C4E);

  static const Color shadow = Color(0x14101828);
  static const Color scrim = Color(0x66000000);

  /// Soft tints used behind product imagery and category tiles.
  static const List<Color> pastelTints = [
    Color(0xFFEAF6EE),
    Color(0xFFFFF3E6),
    Color(0xFFEAF2FD),
    Color(0xFFFDEDEE),
    Color(0xFFF3EEFC),
    Color(0xFFFFF9E0),
    Color(0xFFE8F7F7),
    Color(0xFFF6F0E8),
  ];

  static Color tintFor(String seed) =>
      pastelTints[seed.hashCode.abs() % pastelTints.length];

  static Color fromHex(String? hex, {Color fallback = primaryLight}) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return value == null ? fallback : Color(value);
  }
}
