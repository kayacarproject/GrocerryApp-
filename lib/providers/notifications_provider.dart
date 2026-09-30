import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

final unreadNotificationCountProvider = Provider<int>(
  (ref) =>
      ref.watch(notificationsProvider).valueOrNull?.where((n) => !n.isRead).length ??
      0,
);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.read(notificationRepositoryProvider).getNotifications();
  }

  Future<void> markRead(String id) async {
    final current = state.valueOrNull ?? const [];
    state = AsyncData([
      for (final n in current) n.id == id ? n.markRead() : n,
    ]);
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? const [];
    state = AsyncData([for (final n in current) n.markRead()]);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
