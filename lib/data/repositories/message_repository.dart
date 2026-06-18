import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Mesajlaşma repository arayüzü.
abstract class MessageRepository {
  /// Mevcut kullanıcının tüm konuşmalarını getirir.
  /// Son mesaj zamanına göre sıralanır (en yeni önce).
  Future<List<ConversationModel>> getConversations();

  /// Bir konuşmanın mesajlarını getirir (eski → yeni).
  Future<List<MessageModel>> getMessages(String conversationId);

  /// Belirtilen alıcıya mesaj gönderir.
  /// Konuşma yoksa otomatik oluşturulur.
  Future<MessageModel> sendMessage(String receiverId, String content);

  /// Bir konuşmadaki tüm okunmamış mesajları okundu olarak işaretler.
  Future<void> markMessagesAsRead(String conversationId);
}
