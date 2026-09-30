import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/product.dart';
import '../../../widgets/common/app_image.dart';

/// Swipeable product gallery with a subtle zoom on the active page.
class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key, required this.product});

  final Product product;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images.isEmpty
        ? [ProductImage(url: widget.product.imageUrl)]
        : widget.product.images;
    final baseTint = AppColors.pastelTints.indexOf(AppColors.tintFor(images.first.url));

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => AnimatedScale(
            scale: i == _index ? 1 : 0.92,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: AppImage(
              url: images[i].url,
              emojiScale: 0.5,
              semanticLabel: '${widget.product.name}, image ${i + 1} of ${images.length}',
              // Vary the backdrop per page so demo art feels like a gallery.
              background: AppColors.pastelTints[(baseTint + i) % AppColors.pastelTints.length],
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: AppSpacing.lg,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
