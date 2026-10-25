import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../data/providers/repository_providers.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Notifier
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    // Hesap değişince yeniden kurulur; eski kullanıcının bildirimleri ve kanalı kalmaz.
    final uid = ref.watch(authProvider.select((s) => s.valueOrNull?.id));
    if (uid == null) return const [];
    listenReconnect(ref, ref.invalidateSelf);

    final repo = ref.watch(notificationRepositoryProvider);
    final sub = repo.watchNew(uid).listen(
      _prepend,
      onError: (Object e) => debugPrint('NotificationsNotifier realtime: $e'),
    );
    ref.onDispose(sub.cancel);

    return repo.getNotifications();
  }

  void _prepend(NotificationModel n) {
    final current = state.valueOrNull;
    if (current == null || current.any((c) => c.id == n.id)) return;
    state = AsyncData([n, ...current]);
  }

  void _setRead(bool Function(NotificationModel) match, {required bool isRead}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final n in current) match(n) ? n.copyWith(isRead: isRead) : n,
    ]);
  }

  /// İyimser; hata olursa okunmamışlar geri alınır ve hata fırlatılır.
  Future<void> markAllRead() async {
    final unreadIds = {
      for (final n in state.valueOrNull ?? const <NotificationModel>[])
        if (!n.isRead) n.id,
    };
    if (unreadIds.isEmpty) return;
    _setRead((n) => unreadIds.contains(n.id), isRead: true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } catch (_) {
      _setRead((n) => unreadIds.contains(n.id), isRead: false);
      rethrow;
    }
  }

  /// İyimser; hata olursa geri alınır ve hata fırlatılır.
  Future<void> markRead(String notificationId) async {
    final target = state.valueOrNull?.where((n) => n.id == notificationId).firstOrNull;
    if (target == null || target.isRead) return;
    _setRead((n) => n.id == notificationId, isRead: true);
    try {
      await ref.read(notificationRepositoryProvider).markRead(notificationId);
    } catch (_) {
      _setRead((n) => n.id == notificationId, isRead: false);
      rethrow;
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsNotifier,
      List<NotificationModel>
    >(() {
      return NotificationsNotifier();
    });

/// Okunmamış bildirim sayısı — feed'deki zil rozeti için.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
