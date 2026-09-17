import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/providers/repository_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Conversations Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ConversationsNotifier
    extends AutoDisposeAsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
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
  bool _isDisposed = false;

  @override
  Future<ActiveChatState> build(String peerUserId) async {
    ref.onDispose(() => _isDisposed = true);
    
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
    try {
      await repo.markMessagesAsRead(conversationId);
      // 2. Asenkron aralık sonrası invalidate için _isDisposed güvencesi
      if (!_isDisposed) {
        ref.invalidate(conversationsProvider);
      }
    } catch (e) {
      debugPrint('ActiveChatNotifier: markAsRead hatası: $e');
    }
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
        // TODO: Backend gecikmeleri (eventual consistency) için retry/backoff eklenecek
        final convs = await ref.refresh(conversationsProvider.future);
        convId = convs.firstWhereOrNull((c) => c.otherUser.id == peerUserId)?.id;
      }

      state = AsyncData(ActiveChatState(
        conversationId: convId,
        messages: [...current.messages, newMsg],
      ));

      if (!_isDisposed) {
        ref.invalidate(conversationsProvider);
      }
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
