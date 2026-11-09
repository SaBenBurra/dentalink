import '../models/support_model.dart';

/// Kullanıcının destek sohbeti (049). Personel tarafı admin panelinde.
abstract class SupportRepository {
  /// Kullanıcının sohbeti; henüz hiç yazmadıysa null.
  Future<SupportThread?> getThread();

  /// Sohbetin son [limit] mesajı, eski → yeni. İç notlar RLS ile gelmez.
  Future<List<SupportMessage>> getMessages(String threadId, {int limit});

  /// Sohbet yoksa oluşturur; [category] ve [clientInfo] sohbete yazılır.
  Future<SupportMessage> send(
    String content, {
    SupportCategory? category,
    String? clientInfo,
  });

  /// Sohbetin durum ve okundu değişiklikleri (realtime).
  Stream<SupportThread> watchThread(String userId);

  /// Sohbete düşen yeni mesajlar (realtime).
  Stream<SupportMessage> watchMessages(String threadId);

  Future<void> markRead(String threadId);
}
