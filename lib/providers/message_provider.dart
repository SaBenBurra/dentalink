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
// Chat Notifier (konuşma başına)
// ─────────────────────────────────────────────────────────────────────────────

class ChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String conversationId) async {
    return ref.read(messageRepositoryProvider).getMessages(conversationId);
  }

  /// Konuşmadaki mesajları okundu olarak işaretler.
  /// UI katmanından çağrılmalıdır (ör. ekran açıldığında).
  Future<void> markAsRead() async {
    await ref.read(messageRepositoryProvider).markMessagesAsRead(arg);
  }

  Future<void> sendMessage(String receiverId, String content) async {
    final repo = ref.read(messageRepositoryProvider);
    final newMsg = await repo.sendMessage(receiverId, content);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, newMsg]);
  }
}

final chatProvider = AsyncNotifierProvider.autoDispose
    .family<ChatNotifier, List<MessageModel>, String>(() {
      return ChatNotifier();
    });

/// Toplam okunmamış mesaj sayısı — bottom nav badge için.
final totalUnreadMessagesProvider = Provider.autoDispose<int>((ref) {
  final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
  return conversations.fold(0, (sum, c) => sum + c.unreadCount);
});
