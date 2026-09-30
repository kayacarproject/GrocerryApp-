import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/media_url.dart';
import 'skeletons.dart';

/// Renders catalog imagery from any source the API may return:
/// - `http(s)://...`: cached network image with a shimmer placeholder
/// - `emoji:🍎`: bundled demo art drawn on a soft tint (works offline)
/// - empty: a neutral placeholder icon
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.background,
    this.emojiScale = 0.55,
    this.semanticLabel,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Color? background;
  final double emojiScale;
  final String? semanticLabel;

  static const _emojiPrefix = 'emoji:';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Semantics(
        image: true,
        label: semanticLabel,
        child: ColoredBox(
          color: background ?? AppColors.tintFor(url),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    if (url.startsWith(_emojiPrefix)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          final size = side.isFinite ? side * emojiScale : 48.0;
          return Center(
            child: ExcludeSemantics(
              child: Text(
                url.substring(_emojiPrefix.length),
                style: TextStyle(fontSize: size, height: 1.15),
                textScaler: TextScaler.noScaling,
              ),
            ),
          );
        },
      );
    }
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: MediaUrl.resolve(url),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, _) => const Skeleton(child: SkeletonBox()),
        errorWidget: (_, _, _) => const _Placeholder(),
      );
    }
    return const _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(
      Icons.shopping_basket_outlined,
      color: AppColors.textTertiary,
      size: 32,
    ),
  );
}
