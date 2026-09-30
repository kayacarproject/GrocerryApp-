import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
// import '../../providers/cart_provider.dart';
// import '../../widgets/cart/floating_cart_bar.dart';
import '../../widgets/common/offline_banner.dart';

/// Hosts the five bottom-navigation tabs, each with its own navigation stack.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _cartTab = 3;
  // static const _profileTab = 4;

  void _onTap(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    // final showCartBar =
    //     shell.currentIndex != _cartTab && shell.currentIndex != _profileTab;
    return PopScope(
      // Back from any tab returns to Home before leaving the app.
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onTap(0);
      },
      child: Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Stack(
                children: [
                  shell,
                  // TODO: Restore floating cart bar when ready.
                  // if (showCartBar)
                  //   const Positioned(
                  //     left: 0,
                  //     right: 0,
                  //     bottom: 0,
                  //     child: FloatingCartBar(),
                  //   ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: shell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _items = [
  _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
  _NavItem('Categories', Icons.grid_view_outlined, Icons.grid_view_rounded),
  _NavItem('Search', Icons.search_rounded, Icons.manage_search_rounded),
  _NavItem('Cart', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
  _NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Restore cart badge when ready.
    // final cartCount = ref.watch(cartCountProvider);
    const cartCount = 0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNavHeight,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: _items[i],
                    selected: i == currentIndex,
                    badge: i == MainShell._cartTab ? cartCount : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${item.label}, $badge items' : item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: AppRadius.pillAll,
              ),
              child: Badge(
                isLabelVisible: badge > 0,
                backgroundColor: AppColors.accent,
                textColor: AppColors.textPrimary,
                label: Text(badge > 99 ? '99+' : '$badge'),
                child: Icon(selected ? item.activeIcon : item.icon, color: color, size: 24),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
