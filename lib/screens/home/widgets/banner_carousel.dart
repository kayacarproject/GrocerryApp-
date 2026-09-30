import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_routes.dart';
import '../../../models/home_feed.dart';
import '../../../widgets/common/app_image.dart';

/// Auto-advancing promotional banners with page dots.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<PromoBanner> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final height = (MediaQuery.sizeOf(context).width * 0.42).clamp(140.0, 220.0);
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(height),
          child: NotificationListener<ScrollStartNotification>(
            // Pause auto-play while the user swipes.
            onNotification: (n) {
              if (n.dragDetails != null) _startAutoPlay();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _BannerCard(banner: widget.banners[i]),
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.primary : AppColors.border,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(banner.colorHex, fallback: AppColors.primary);
    final categoryId = banner.categoryId;
    return Semantics(
      button: true,
      label: '${banner.title.replaceAll('\n', ' ')}. ${banner.subtitle}. ${banner.ctaLabel}',
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: AppRadius.xlAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => categoryId == null
              ? context.go(AppRoutes.categories)
              : context.push(AppRoutes.category(categoryId)),
          child: Stack(
            children: [
              // Soft decorative circles.
              Positioned(
                right: -40,
                top: -30,
                child: _Circle(size: 180, color: Colors.white.withValues(alpha: 0.1)),
              ),
              Positioned(
                right: 40,
                bottom: -60,
                child: _Circle(size: 140, color: Colors.white.withValues(alpha: 0.08)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            banner.subtitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white70,
                              letterSpacing: 0.8,
                            ),
                          ),
                          AppSpacing.gapXs,
                          Flexible(
                            child: Text(
                              banner.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3.copyWith(color: Colors.white),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs + 2,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppRadius.pillAll,
                            ),
                            child: Text(
                              banner.ctaLabel,
                              style: AppTextStyles.label.copyWith(color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: AppImage(
                            url: banner.imageUrl,
                            borderRadius: AppRadius.lgAll,
                            background: Colors.transparent,
                            emojiScale: 0.75,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
