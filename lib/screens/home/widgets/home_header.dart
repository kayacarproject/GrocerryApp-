import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notifications_provider.dart';

/// Delivery location selector with notification and profile shortcuts.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(selectedAddressProvider);
    final user = ref.watch(currentUserProvider);
    final unread =
        AppConfig.notificationsEnabled ? ref.watch(unreadNotificationCountProvider) : 0;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: address == null
                ? 'Select delivery location'
                : 'Delivering to ${address.name}, ${address.shortAddress}. Change location',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: AppRadius.mdAll,
              onTap: () => context.push(AppRoutes.location),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                        Text(
                          'Delivery in 12 minutes',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address == null
                                ? 'Select delivery location'
                                : 'Deliver to ${address.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h3,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                    if (address != null)
                      Text(
                        address.shortAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (AppConfig.notificationsEnabled)
          IconButton(
            tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              smallSize: 9,
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          )
        else
          AppSpacing.gapSm,
        Semantics(
          button: true,
          label: 'Profile',
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => context.go(AppRoutes.profile),
            radius: 26,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                (user?.name ?? '').initials,
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
