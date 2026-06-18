import '../datasources/mock_datasource.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'message_repository.dart';

/// Sahte mesajlaşma repository. Faz 3'te SupabaseMessageRepository ile swap edilir.
class MockMessageRepository implements MessageRepository {
  static const _delay = Duration(milliseconds: 350);

  // In-memory konuşma ve mesaj listeleri.
  final List<ConversationModel> _conversations =
      List.from(MockDatasource.conversations);
  final Map<String, List<MessageModel>> _messages = {
    for (final e in MockDatasource.messages.entries)
      e.key: List.from(e.value),
  };

  @override
  Future<List<ConversationModel>> getConversations() async {
    await Future.delayed(_delay);
    final sorted = List<ConversationModel>.from(_conversations);
    sorted.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime(2000);
      final bTime = b.lastMessageAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    await Future.delayed(_delay);
    return List.from(_messages[conversationId] ?? []);
  }

  @override
  Future<MessageModel> sendMessage(String receiverId, String content) async {
    await Future.delayed(_delay);
    final newMessage = MessageModel(
      id: 'm_new_${DateTime.now().millisecondsSinceEpoch}',
      senderId: MockDatasource.currentUserId,
      receiverId: receiverId,
      content: content,
      isRead: false,
      createdAt: DateTime.now(),
    );

    // İlgili konuşmayı bul.
    final convIdx = _conversations.indexWhere(
      (c) => c.otherUser.id == receiverId,
    );

    String convId;
    if (convIdx != -1) {
      convId = _conversations[convIdx].id;
      _conversations[convIdx] = _conversations[convIdx].copyWith(
        lastMessageAt: DateTime.now(),
        lastMessagePreview: content.length > 80
            ? '${content.substring(0, 80)}...'
            : content,
        unreadCount: 0,
      );
    } else {
      // Yeni konuşma oluştur.
      convId = 'conv_new_${DateTime.now().millisecondsSinceEpoch}';
      _conversations.add(ConversationModel(
        id: convId,
        otherUser: MockDatasource.userById(receiverId),
        lastMessageAt: DateTime.now(),
        lastMessagePreview: content,
        unreadCount: 0,
      ));
    }

    _messages[convId] = [...(_messages[convId] ?? []), newMessage];
    return newMessage;
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
    }
    final msgs = _messages[conversationId];
    if (msgs != null) {
      _messages[conversationId] = msgs.map((m) => m.copyWith(isRead: true)).toList();
    }
  }
}
