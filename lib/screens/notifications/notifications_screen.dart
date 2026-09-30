import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/common/async_value_view.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeletons.dart';

extension on NotificationType {
  (IconData, Color) get style => switch (this) {
    NotificationType.order => (Icons.receipt_long_rounded, AppColors.primary),
    NotificationType.offer => (Icons.local_offer_rounded, const Color(0xFFC2410C)),
    NotificationType.system => (Icons.info_outline_rounded, AppColors.info),
  };
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(notificationsProvider.notifier).markAllRead();
                } catch (error) {
                  if (context.mounted) {
                    context.showSnack(ApiException.messageOf(error), isError: true);
                  }
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: AsyncValueView<List<AppNotification>>(
          value: notifications,
          onRetry: () => ref.invalidate(notificationsProvider),
          loading: const ListSkeleton(count: 5, item: TileSkeleton()),
          data: (items) => items.isEmpty
              ? const EmptyStateView(
                  icon: Icons.notifications_off_outlined,
                  title: 'No notifications',
                  message: 'Order updates and offers will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(indent: 72),
                  itemBuilder: (_, i) => _NotificationTile(notification: items[i]),
                ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = notification.type.style;
    return Material(
      color: notification.isRead ? Colors.transparent : AppColors.primaryLight.withValues(alpha: 0.5),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationsProvider.notifier).markRead(notification.id);
          }
          final orderId = notification.orderId;
          if (orderId != null) context.push(AppRoutes.orderDetail(orderId));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(Formatters.relative(notification.createdAt), style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(notification.body, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                AppSpacing.gapSm,
                Semantics(
                  label: 'Unread',
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
