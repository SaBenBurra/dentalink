import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/mock_notification_repository.dart';
import '../data/repositories/notification_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ─────────────────────────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Notifier
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return ref.read(notificationRepositoryProvider).getNotifications();
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
  }

  Future<void> markRead(String notificationId) async {
    await ref.read(notificationRepositoryProvider).markRead(notificationId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }
}

final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});

/// Okunmamış bildirim sayısı — bottom nav badge için.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
