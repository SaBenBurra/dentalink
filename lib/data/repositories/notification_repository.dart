import '../models/notification_model.dart';

/// Bildirim repository arayüzü.
abstract class NotificationRepository {
  /// Mevcut kullanıcının bildirimlerini getirir (en yeni önce).
  Future<List<NotificationModel>> getNotifications();

  /// Okunmamış bildirim sayısını döndürür.
  Future<int> getUnreadCount();

  /// Tüm bildirimleri okundu olarak işaretler.
  Future<void> markAllRead();

  /// Tek bir bildirimi okundu olarak işaretler.
  Future<void> markRead(String notificationId);
}
