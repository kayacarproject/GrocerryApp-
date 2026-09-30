import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../providers/core_providers.dart';
import '../../widgets/common/app_button.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.emojis,
    required this.title,
    required this.message,
    required this.tint,
  });

  final List<String> emojis;
  final String title;
  final String message;
  final Color tint;
}

const _pages = [
  _OnboardingPage(
    emojis: ['🥬', '🍎', '🥛', '🍞'],
    title: 'Everything you need,\nin one basket',
    message: 'Fresh produce, daily essentials and pantry staples from trusted local stores.',
    tint: Color(0xFFE3F4E8),
  ),
  _OnboardingPage(
    emojis: ['🛵', '⏱️', '🏠', '📦'],
    title: 'Delivered to your door\nin minutes',
    message: 'Lightning-fast express delivery, or pick a slot that fits your day.',
    tint: Color(0xFFFFF0DA),
  ),
  _OnboardingPage(
    emojis: ['🏷️', '💸', '🎁', '⭐'],
    title: 'Great prices,\nevery single day',
    message: AppConfig.couponsEnabled
        ? 'Exclusive deals, coupons and real savings on every order.'
        : 'Exclusive deals and real savings on every order.',
    tint: Color(0xFFE6EFFC),
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(localCacheProvider).setOnboardingSeen();
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _isLast ? null : _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.border,
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: AppButton(
                label: _isLast ? 'Get started' : 'Next',
                icon: _isLast ? null : Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final art = math.max(
          120.0,
          math.min(constraints.maxWidth * 0.72, constraints.maxHeight * 0.5),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: art,
                    height: art,
                    decoration: BoxDecoration(color: page.tint, shape: BoxShape.circle),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            page.emojis.first,
                            style: TextStyle(fontSize: art * 0.34),
                            textScaler: TextScaler.noScaling,
                          ),
                        ),
                        for (final (i, align) in const [
                          Alignment(-0.7, -0.6),
                          Alignment(0.75, -0.45),
                          Alignment(0.6, 0.7),
                        ].indexed)
                          Align(
                            alignment: align,
                            child: Container(
                              padding: EdgeInsets.all(art * 0.035),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12)],
                              ),
                              child: Text(
                                page.emojis[i + 1],
                                style: TextStyle(fontSize: art * 0.11),
                                textScaler: TextScaler.noScaling,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
                Text(page.title, textAlign: TextAlign.center, style: AppTextStyles.h1),
                AppSpacing.gapMd,
                Text(
                  page.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
