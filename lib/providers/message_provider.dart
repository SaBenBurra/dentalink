import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/paging.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/providers/repository_providers.dart';
import 'auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Conversations Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ConversationsNotifier
    extends AutoDisposeAsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    // Hesap değişince yeniden kurulur; eski kullanıcının sohbetleri ve kanalı kalmaz.
    final uid = ref.watch(authProvider.select((s) => s.valueOrNull?.id));
    if (uid == null) return const [];

    final repo = ref.watch(messageRepositoryProvider);
    final sub = repo.watchConversations(uid).listen(
      _upsert,
      onError: (Object e) => debugPrint('ConversationsNotifier realtime: $e'),
    );
    ref.onDispose(sub.cancel);

    return repo.getConversations();
  }

  /// Gelen sohbeti listede günceller (yoksa ekler); son mesaja göre sıralar.
  void _upsert(ConversationModel c) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      [c, for (final x in current) if (x.id != c.id) x]..sort(_byLastMessageDesc),
    );
  }

  static int _byLastMessageDesc(ConversationModel a, ConversationModel b) {
    final x = a.lastMessageAt, y = b.lastMessageAt;
    if (x == null || y == null) return x == y ? 0 : (x == null ? 1 : -1);
    return y.compareTo(x);
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

/// id ile tekilleştirir (sonraki kazanır: realtime UPDATE eskiyi ezer), eski → yeni sıralar.
List<MessageModel> _merge(List<MessageModel> a, Iterable<MessageModel> b) =>
    {for (final m in [...a, ...b]) m.id: m}.values.toList()
      ..sort((x, y) => x.createdAt.compareTo(y.createdAt));

class ActiveChatNotifier
    extends AutoDisposeFamilyAsyncNotifier<ActiveChatState, String> {
  final _pager = Pager<MessageModel>();

  /// Yüklenenden daha eski mesaj var mı.
  bool get hasMore => _pager.hasMore;

  @override
  Future<ActiveChatState> build(String peerUserId) async {
    // 9. Sohbet ekranından kısa süreli çıkıp girmelerde yeniden yüklemeyi (flicker) önler
    final link = ref.keepAlive();
    final timer = Timer(const Duration(minutes: 5), link.close);
    ref.onDispose(timer.cancel);

    // 7. getConversations()'ı doğrudan repo yerine sadece bu sohbete ait id'yi dinle
    final conversationId = ref.watch(
      _peerConversationProvider(peerUserId).select((c) => c?.id),
    );

    if (conversationId == null) {
      _pager.reset();
      return const ActiveChatState(conversationId: null, messages: []);
    }

    final repo = ref.watch(messageRepositoryProvider);
    // İlk yükleme sürerken gelen olaylar kaybolmasın diye tamponlanır.
    final early = <MessageModel>[];
    var loaded = false;
    final sub = repo.watchMessages(conversationId).listen(
      (m) => loaded ? _upsert(m) : early.add(m),
      onError: (Object e) => debugPrint('ActiveChatNotifier realtime: $e'),
    );
    ref.onDispose(sub.cancel);

    final messages = _pager.first(await repo.getMessages(conversationId));
    loaded = true;

    return ActiveChatState(
      conversationId: conversationId,
      messages: _merge(messages, early),
    );
  }

  void _upsert(MessageModel m) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(messages: _merge(current.messages, [m])));
  }

  /// Daha eski mesaj sayfasını başa ekler; ekrandaki (realtime ile güncellenmiş)
  /// kopyalar korunur.
  Future<void> loadMore() {
    final conversationId = state.valueOrNull?.conversationId;
    if (conversationId == null) return Future.value();
    return _pager.loadMore(
      (before) => ref
          .read(messageRepositoryProvider)
          .getMessages(conversationId, before: before),
      (older) {
        final current = state.valueOrNull;
        if (current == null) return;
        state = AsyncData(current.copyWith(messages: _merge(older, current.messages)));
      },
    );
  }

  /// Mesajları okundu olarak işaretler. UI katmanından (ör. ekran açılışı) tetiklenir.
  Future<void> markAsRead(String conversationId) async {
    final repo = ref.read(messageRepositoryProvider);
    await repo.markMessagesAsRead(conversationId);
    // unread_count değişikliği conversations realtime'ı ile listeye düşer.
  }

  Future<void> sendMessage(String content) async {
    final newMsg = await ref.read(messageRepositoryProvider).sendMessage(arg, content);
    // Yükleme sürerken gönderildiyse mesaj düşmesin.
    final current = await future;
    state = AsyncData(current.copyWith(messages: _merge(current.messages, [newMsg])));

    // İlk mesaj: sohbet yeni oluştu. Liste yenilenince build bu sohbetin
    // kanalına abone olur ve mesajları baştan çeker.
    if (current.conversationId == null) {
      ref.invalidate(conversationsProvider);
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
