import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_failures.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'message_repository.dart';

class SupabaseMessageRepository implements MessageRepository {
  final SupabaseClient _client;

  SupabaseMessageRepository({required SupabaseClient client}) : _client = client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthRequiredFailure();
    return id;
  }

  ConversationModel _mapConversation(Map<String, dynamic> row, String currentUserId) {
    final isUser1 = row['user1_id'] == currentUserId;
    final otherUserData = isUser1 ? row['user2'] : row['user1'];
    
    if (otherUserData == null) {
      throw const ServerFailure(message: 'Karşı kullanıcı bilgisi alınamadı.');
    }

    final unreadCount = isUser1 ? (row['user1_unread_count'] as int? ?? 0) : (row['user2_unread_count'] as int? ?? 0);
    
    return ConversationModel(
      id: row['id'] as String,
      otherUser: UserModel.fromJson(otherUserData as Map<String, dynamic>),
      lastMessageAt: row['last_message_at'] != null ? DateTime.parse(row['last_message_at'] as String) : null,
      lastMessagePreview: row['last_message_preview'] as String?,
      unreadCount: unreadCount,
    );
  }

  MessageModel _mapMessage(Map<String, dynamic> row) {
    return MessageModel(
      id: row['id'] as String,
      senderId: row['sender_id'] as String,
      receiverId: row['receiver_id'] as String,
      content: row['content'] as String,
      isRead: row['is_read'] as bool? ?? false,
      deletedAt: row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<List<ConversationModel>> getConversations() => guardSupabase(() async {
    final uid = _uid;
    // Güvenlik: users tablosundan sadece gerekli alanlar çekiliyor
    const userSelect = 'id, full_name, username, avatar_url, title, is_verified, created_at';
    final response = await _client
        .from('conversations')
        .select('*, user1:users!conversations_user1_id_fkey($userSelect), user2:users!conversations_user2_id_fkey($userSelect)')
        .or('user1_id.eq.$uid,user2_id.eq.$uid')
        .order('last_message_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => _mapConversation(e as Map<String, dynamic>, uid))
        .toList();
  });

  @override
  Future<List<MessageModel>> getMessages(String conversationId) => guardSupabase(() async {
    final response = await _client
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((e) => _mapMessage(e as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<MessageModel> sendMessage(String receiverId, String content) => guardSupabase(() async {
    final uid = _uid; // ensure authenticated
    
    if (uid == receiverId) {
      throw const ValidationFailure('Kendinize mesaj gönderemezsiniz.');
    }
    
    // Güvenlik ve Race Condition koruması: Filtre yerine RPC kullanımı.
    // RPC, LEAST/GREATEST mantığıyla conflictleri tek transaction'da engeller.
    final convIdResponse = await _client.rpc('get_or_create_conversation', params: {
      'p_other_user_id': receiverId
    });
    
    final conversationId = convIdResponse as String;

    final msgRow = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': _uid,
          'receiver_id': receiverId,
          'content': content,
        })
        .select('*')
        .single();
        
    return _mapMessage(msgRow);
  });

  @override
  Future<void> markMessagesAsRead(String conversationId) => guardSupabase(() async {
    final _ = _uid; // ensure authenticated
    await _client.rpc('mark_messages_as_read', params: {
      'p_conversation_id': conversationId
    });
  });
}
