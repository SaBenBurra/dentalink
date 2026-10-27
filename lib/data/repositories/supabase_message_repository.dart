import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_failures.dart';
import '../../core/utils/paging.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'keyset.dart';
import 'message_repository.dart';

class SupabaseMessageRepository implements MessageRepository {
  final SupabaseClient _client;

  SupabaseMessageRepository({required this._client});

  // Güvenlik: users tablosundan sadece gerekli alanlar çekiliyor
  static const _userSelect = 'id, full_name, username, avatar_url, title, is_verified, created_at';
  static const _conversationSelect =
      '*, user1:users!conversations_user1_id_fkey($_userSelect), user2:users!conversations_user2_id_fkey($_userSelect)';

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
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  @override
  Future<List<ConversationModel>> getConversations() => guardSupabase(() async {
    final uid = _uid;
    final response = await _client
        .from('conversations')
        .select(_conversationSelect)
        .or('user1_id.eq.$uid,user2_id.eq.$uid')
        .order('last_message_at', ascending: false, nullsFirst: false);

    return (response as List<dynamic>)
        .map((e) => _mapConversation(e as Map<String, dynamic>, uid))
        .toList();
  });

  @override
  Future<PageResult<MessageModel>> getMessages(
    String conversationId, {
    PageCursor? before,
  }) => guardSupabase(() async {
    // Sayfa en yeniden geriye çekilir, ekran için eski → yeni çevrilir.
    final rows = await _client
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .pageBefore(before);

    return (
      items: rows.reversed.map(_mapMessage).toList(),
      next: nextCursor(rows),
    );
  });

  @override
  Future<MessageModel> sendMessage(String receiverId, String content) => guardSupabase(() async {
    if (_uid == receiverId) {
      throw const ValidationFailure('Kendinize mesaj gönderemezsiniz.');
    }
    // Sohbet get-or-create + insert tek işlemde (migration 014).
    final row = await _client.rpc('send_message', params: {
      'p_receiver_id': receiverId,
      'p_content': content,
    });
    return _mapMessage(row as Map<String, dynamic>);
  });

  @override
  Stream<MessageModel> watchMessages(String conversationId) {
    RealtimeChannel? channel;
    late final StreamController<MessageModel> controller;
    controller = StreamController<MessageModel>(
      onListen: () {
        channel = _client
            .channel('public:messages:conversation_id=$conversationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (payload) {
                // Yalnızca soft delete var; DELETE olayının newRecord'u boş.
                if (payload.newRecord.isEmpty || controller.isClosed) return;
                controller.add(_mapMessage(payload.newRecord));
              },
            )
            .subscribe();
      },
      onCancel: () async {
        if (channel != null) await _client.removeChannel(channel!);
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Stream<ConversationModel> watchConversations(String userId) {
    RealtimeChannel? channel;
    late final StreamController<ConversationModel> controller;

    // Payload'da karşı kullanıcı join'i yok; tek satırı join ile çek.
    Future<void> emit(String id) async {
      try {
        final row = await guardSupabase(() => _client
            .from('conversations')
            .select(_conversationSelect)
            .eq('id', id)
            .maybeSingle());
        if (row != null && !controller.isClosed) controller.add(_mapConversation(row, userId));
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    void onChange(PostgresChangePayload payload) {
      final id = payload.newRecord['id'] as String?;
      if (id != null) emit(id);
    }

    // Filtre tek kolon alıyor; kullanıcı user1 de user2 de olabilir.
    PostgresChangeFilter filterOn(String column) => PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: userId,
        );

    controller = StreamController<ConversationModel>(
      onListen: () {
        channel = _client
            .channel('public:conversations:uid=$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'conversations',
              filter: filterOn('user1_id'),
              callback: onChange,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'conversations',
              filter: filterOn('user2_id'),
              callback: onChange,
            )
            .subscribe();
      },
      onCancel: () async {
        if (channel != null) await _client.removeChannel(channel!);
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> markMessagesAsRead(String conversationId) => guardSupabase(() async {
    final _ = _uid; // ensure authenticated
    await _client.rpc('mark_messages_as_read', params: {
      'p_conversation_id': conversationId
    });
  });
}
