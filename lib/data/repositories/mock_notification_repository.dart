import '../datasources/mock_datasource.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

/// Sahte bildirim repository. Faz 3'te SupabaseNotificationRepository ile swap edilir.
class MockNotificationRepository implements NotificationRepository {
  static const _delay = Duration(milliseconds: 300);

  final List<NotificationModel> _notifications = List.from(
    MockDatasource.notifications,
  );

  @override
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(_delay);
    final sorted = List<NotificationModel>.from(_notifications);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markAllRead() async {
    await Future.delayed(_delay);
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    }
  }
}
