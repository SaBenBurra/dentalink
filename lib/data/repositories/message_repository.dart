import '../../core/utils/paging.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Mesajlaşma repository arayüzü.
abstract class MessageRepository {
  /// Mevcut kullanıcının tüm konuşmalarını getirir (sayfasız: sohbet ekranı
  /// karşı kullanıcının konuşmasını ve okunmamış toplamını bu listeden bulur).
  /// Son mesaj zamanına göre sıralanır (en yeni önce).
  Future<List<ConversationModel>> getConversations();

  /// Bir konuşmanın en yeni mesaj sayfası, eski → yeni sıralı; [before]
  /// verilirse ondan önceki (daha eski) sayfa.
  Future<PageResult<MessageModel>> getMessages(String conversationId, {PageCursor? before});

  /// Belirtilen alıcıya mesaj gönderir.
  /// Konuşma yoksa otomatik oluşturulur.
  Future<MessageModel> sendMessage(String receiverId, String content);

  /// Konuşmadaki yeni ve güncellenen mesajlar (realtime).
  Stream<MessageModel> watchMessages(String conversationId);

  /// Kullanıcının yeni ya da güncellenen konuşmaları (realtime, karşı kullanıcıyla).
  Stream<ConversationModel> watchConversations(String userId);

  /// Bir konuşmadaki tüm okunmamış mesajları okundu olarak işaretler.
  Future<void> markMessagesAsRead(String conversationId);
}
