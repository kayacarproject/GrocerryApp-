import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(md);

  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
}

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}

abstract final class AppSizes {
  /// Material accessibility guideline for tappable targets.
  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;
  static const double buttonHeightSm = 36;

  static const double iconSm = 16;
  static const double iconMd = 22;
  static const double iconLg = 28;

  static const double bottomNavHeight = 68;
  static const double floatingCartBarHeight = 60;
  static const double avatar = 72;

  /// Product card width for horizontal rails, derived from screen width so
  /// roughly 2.3 cards are visible on any phone.
  static double railCardWidth(double screenWidth) =>
      (screenWidth / 2.35).clamp(140.0, 190.0);

  /// Column count for product grids.
  static int gridColumns(double width) => width >= 600 ? 3 : 2;

  static const double productImageAspectRatio = 1.08;

  /// Height a product card of [width] needs. Accounts for the user's text
  /// scale so content never overflows on small phones or with large fonts.
  static double productCardHeight(BuildContext context, double width) {
    final imageHeight =
        (width - AppSpacing.sm * 2) / productImageAspectRatio;
    final textArea = MediaQuery.textScalerOf(context).scale(118);
    return imageHeight + textArea + AppSpacing.sm * 2 + 14;
  }

  /// Width of one grid cell given the available [width].
  static double gridCellWidth(double width) {
    final columns = gridColumns(width);
    return (width - AppSpacing.lg * 2 - AppSpacing.md * (columns - 1)) /
        columns;
  }
}
