import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/providers/repository_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Conversations Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ConversationsNotifier
    extends AutoDisposeAsyncNotifier<List<ConversationModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<ConversationModel>> build() async {
    final client = ref.watch(supabaseClientProvider);
    final uid = client.auth.currentUser?.id;

    if (uid != null) {
      _channel = client
          .channel('public:conversations:uid=$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (payload) {
              final rec = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
              if (rec['user1_id'] == uid || rec['user2_id'] == uid) {
                ref.invalidateSelf();
              }
            },
          )
          .subscribe();

      ref.onDispose(() {
        _channel?.unsubscribe();
      });
    }

    return ref.read(messageRepositoryProvider).getConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(messageRepositoryProvider).getConversations(),
    );
  }
}

final conversationsProvider =
    AsyncNotifierProvider.autoDispose<
      ConversationsNotifier,
      List<ConversationModel>
    >(() {
      return ConversationsNotifier();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Active Chat State & Notifier (peer kullanıcı ID'si ile anahtarlanır)
// ─────────────────────────────────────────────────────────────────────────────

final _peerConversationProvider = Provider.autoDispose.family<ConversationModel?, String>((ref, peerId) {
  final list = ref.watch(conversationsProvider).valueOrNull ?? [];
  return list.firstWhereOrNull((c) => c.otherUser.id == peerId);
});


class ActiveChatState {
  final String? conversationId;
  final List<MessageModel> messages;

  const ActiveChatState({this.conversationId, required this.messages});

  ActiveChatState copyWith({
    String? conversationId,
    List<MessageModel>? messages,
  }) {
    return ActiveChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
    );
  }
}

class ActiveChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActiveChatState, String> {
  RealtimeChannel? _channel;

  @override
  Future<ActiveChatState> build(String peerUserId) async {
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    
    // 9. Sohbet ekranından kısa süreli çıkıp girmelerde yeniden yüklemeyi (flicker) önler
    final link = ref.keepAlive();
    final timer = Timer(const Duration(minutes: 5), link.close);
    ref.onDispose(timer.cancel);

    // 7. getConversations()'ı doğrudan repo yerine sadece bu sohbete ait id'yi dinle
    final conversationId = ref.watch(
      _peerConversationProvider(peerUserId).select((c) => c?.id),
    );

    if (conversationId == null) {
      return const ActiveChatState(conversationId: null, messages: []);
    }

    final client = ref.watch(supabaseClientProvider);
    _channel = client
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
            ref.invalidateSelf();
          },
        )
        .subscribe();

    final repo = ref.read(messageRepositoryProvider);
    // TODO: Sayfalama/lazy loading eklenebilir (cursor/limit)
    final messages = await repo.getMessages(conversationId);

    return ActiveChatState(
      conversationId: conversationId,
      messages: messages,
    );
  }

  /// Mesajları okundu olarak işaretler. UI katmanından (ör. ekran açılışı) tetiklenir.
  Future<void> markAsRead(String conversationId) async {
    final repo = ref.read(messageRepositoryProvider);
    await repo.markMessagesAsRead(conversationId);
    // Not: conversationsProvider'ı manuel invalidate etmeye gerek yok, 
    // Realtime (ConversationsNotifier içindeki) unread_count değişikliğini algılayıp 
    // otomatik refresh yapacaktır.
  }

  Future<void> sendMessage(String content) async {
    final repo = ref.read(messageRepositoryProvider);
    final peerUserId = arg;

    try {
      final newMsg = await repo.sendMessage(peerUserId, content);
      
      // 3. Mesaj gönderiminde silent data loss'u önlemek için
      // state'in yüklenmesini bekleyerek güncel veriyi güvenle al.
      final current = await future;
      
      String? convId = current.conversationId;
      if (convId == null) {
        // Yeni konuşma ID'sini repodan tazeleyip buluyoruz.
        final convs = await ref.refresh(conversationsProvider.future);
        convId = convs.firstWhereOrNull((c) => c.otherUser.id == peerUserId)?.id;
      }

      // Race condition (realtime duplicate) önlemek için ID bazlı tekilleştirme:
      final merged = {
        for (final m in [...current.messages, newMsg]) m.id: m
      }.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      state = AsyncData(ActiveChatState(
        conversationId: convId,
        messages: merged,
      ));

      // Not: conversationsProvider'ı manuel invalidate etmeye gerek yok, 
      // Realtime tetikleyecektir.
    } catch (e, st) {
      debugPrint('ActiveChatNotifier: sendMessage hatası: $e\n$st');
      rethrow; // UI hatayı yakalayacak
    }
  }
}

final activeChatProvider = AsyncNotifierProvider.autoDispose
    .family<ActiveChatNotifier, ActiveChatState, String>(() {
      return ActiveChatNotifier();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Diğer Provider'lar
// ─────────────────────────────────────────────────────────────────────────────

/// Toplam okunmamış mesaj sayısı — bottom nav badge için.
final totalUnreadMessagesProvider = Provider.autoDispose<int>((ref) {
  final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
  return conversations.fold(0, (sum, c) => sum + c.unreadCount);
});
