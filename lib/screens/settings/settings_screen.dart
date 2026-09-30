import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/recently_viewed_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear cached data?',
      message:
          'Saved categories, recently viewed items and recent searches will be removed '
          'from this device. Your account and orders are not affected.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;
    await ref.read(localCacheProvider).clearCatalogCache();
    ref.read(recentlyViewedProvider.notifier).clear();
    ref.read(searchProvider.notifier).clearRecent();
    ref.invalidate(categoriesProvider);
    ref.invalidate(homeFeedProvider);
    if (context.mounted) context.showSnack('Cache cleared');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (AppConfig.notificationsEnabled) ...[
            const _GroupTitle('Notifications'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.local_shipping_outlined),
                    title: Text('Order updates', style: AppTextStyles.body),
                    subtitle: const Text('Status changes and delivery alerts'),
                    value: settings.orderUpdates,
                    onChanged: (v) => notifier.update(settings.copyWith(orderUpdates: v)),
                  ),
                  const Divider(indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.local_offer_outlined),
                    title: Text('Offers & promotions', style: AppTextStyles.body),
                    subtitle: const Text('Deals, coupons and new arrivals'),
                    value: settings.offersAndPromotions,
                    onChanged: (v) => notifier.update(settings.copyWith(offersAndPromotions: v)),
                  ),
                  const Divider(indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.chat_outlined),
                    title: Text('Updates on WhatsApp', style: AppTextStyles.body),
                    value: settings.whatsappUpdates,
                    onChanged: (v) => notifier.update(settings.copyWith(whatsappUpdates: v)),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXl,
          ],
          const _GroupTitle('Account & data'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text('Manage addresses', style: AppTextStyles.body),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.addresses),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: Text('Clear cache', style: AppTextStyles.body),
                  subtitle: const Text('Free up space used by offline data'),
                  onTap: () => _clearCache(context, ref),
                ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const _GroupTitle('About'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text('About ${AppConfig.appName}', style: AppTextStyles.body),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.info(InfoPage.about)),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: Text('App version', style: AppTextStyles.body),
                  trailing: Text(
                    AppConfig.appVersion,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
    child: Text(text.toUpperCase(), style: AppTextStyles.caption.copyWith(letterSpacing: 0.8)),
  );
}
