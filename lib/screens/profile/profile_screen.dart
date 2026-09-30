import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/dialogs.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You\'ll need to log in again to place orders.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(authProvider.notifier).logout();
    } catch (error) {
      if (context.mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final orderCount = ref.watch(ordersProvider).valueOrNull?.length;
    final wishlistCount = ref.watch(wishlistIdsProvider).length;
    final unread =
        AppConfig.notificationsEnabled ? ref.watch(unreadNotificationCountProvider) : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('My account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            onTap: () => context.push(AppRoutes.editProfile),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.avatar / 2,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (user?.name ?? '').initials,
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                ),
                AppSpacing.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(user?.email ?? '', style: AppTextStyles.bodySmall),
                      Text(
                        user == null || user.phone.isEmpty ? '' : '+91 ${user.phone}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: AppColors.primary),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.receipt_long_outlined,
                  value: orderCount?.toString() ?? '–',
                  label: 'Orders',
                  onTap: () => context.push(AppRoutes.orders),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: _StatTile(
                  icon: Icons.favorite_border_rounded,
                  value: '$wishlistCount',
                  label: 'Wishlist',
                  onTap: () => context.push(AppRoutes.wishlist),
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          _MenuGroup(
            items: [
              _MenuItem(Icons.receipt_long_outlined, 'My Orders', () => context.push(AppRoutes.orders)),
              _MenuItem(Icons.favorite_border_rounded, 'Wishlist', () => context.push(AppRoutes.wishlist)),
              _MenuItem(Icons.location_on_outlined, 'Addresses', () => context.push(AppRoutes.addresses)),
              if (AppConfig.notificationsEnabled)
                _MenuItem(
                  Icons.notifications_none_rounded,
                  'Notifications',
                  () => context.push(AppRoutes.notifications),
                  badge: unread,
                ),
              _MenuItem(
                Icons.account_balance_wallet_outlined,
                'Payments',
                () => context.push(AppRoutes.info(InfoPage.payments)),
              ),
            ],
          ),
          AppSpacing.gapLg,
          _MenuGroup(
            items: [
              _MenuItem(Icons.settings_outlined, 'Settings', () => context.push(AppRoutes.settings)),
              if (AppConfig.supportPagesEnabled) ...[
                _MenuItem(Icons.support_agent_rounded, 'Help & Support', () => context.push(AppRoutes.info(InfoPage.help))),
                _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () => context.push(AppRoutes.info(InfoPage.privacy))),
                _MenuItem(Icons.description_outlined, 'Terms & Conditions', () => context.push(AppRoutes.info(InfoPage.terms))),
              ],
            ],
          ),
          AppSpacing.gapLg,
          _MenuGroup(
            items: [
              _MenuItem(
                Icons.logout_rounded,
                'Logout',
                () => _logout(context, ref),
                destructive: true,
              ),
            ],
          ),
          AppSpacing.gapXl,
          Center(
            child: Text(
              '${AppConfig.appName} v${AppConfig.appVersion}'
              '${AppConfig.useMockData ? ' · Demo mode' : ''}',
              style: AppTextStyles.caption,
            ),
          ),
          AppSpacing.gapLg,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          AppSpacing.gapMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h3),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap, {this.badge = 0, this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final bool destructive;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 56),
            ListTile(
              onTap: items[i].onTap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(AppRadius.lg) : Radius.zero,
                  bottom: i == items.length - 1 ? const Radius.circular(AppRadius.lg) : Radius.zero,
                ),
              ),
              leading: Icon(
                items[i].icon,
                color: items[i].destructive ? AppColors.error : AppColors.textSecondary,
              ),
              title: Text(
                items[i].label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: items[i].destructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (items[i].badge > 0)
                    Badge(
                      label: Text('${items[i].badge}'),
                      backgroundColor: AppColors.error,
                    ),
                  if (!items[i].destructive)
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
