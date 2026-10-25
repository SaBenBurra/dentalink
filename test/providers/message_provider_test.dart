import 'dart:async';

import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/conversation_model.dart';
import 'package:dentlink/data/models/message_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/message_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/providers/message_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

const _me = 'mock_test_user_id';

UserModel _user(String id) => UserModel(
      id: id,
      fullName: id,
      username: id,
      title: UserTitle.disHekimi,
      createdAt: DateTime(2026),
    );

ConversationModel _conv(String id, String peer, {int? minute}) => ConversationModel(
      id: id,
      otherUser: _user(peer),
      lastMessageAt: minute == null ? null : DateTime(2026, 1, 1, 0, minute),
    );

MessageModel _msg(String id, int minute, {String content = 'x'}) => MessageModel(
      id: id,
      senderId: 'peer',
      receiverId: _me,
      content: content,
      createdAt: DateTime(2026, 1, 1, 0, minute),
    );

class _FakeMessageRepo implements MessageRepository {
  final convLive = StreamController<ConversationModel>.broadcast();
  final msgLive = StreamController<MessageModel>.broadcast();
  List<ConversationModel> conversations = [];
  Completer<List<MessageModel>> messagesLoad = Completer();
  PageCursor? firstPageNext;
  final befores = <PageCursor?>[];
  int getConversationsCalls = 0;

  @override
  Future<List<ConversationModel>> getConversations() async {
    getConversationsCalls++;
    return conversations;
  }

  @override
  Future<PageResult<MessageModel>> getMessages(String conversationId,
      {PageCursor? before}) async {
    befores.add(before);
    if (before != null) return (items: [_msg('m0', 0)], next: null);
    return (items: await messagesLoad.future, next: firstPageNext);
  }

  @override
  Future<MessageModel> sendMessage(String receiverId, String content) async {
    // RPC sohbeti de oluşturur.
    conversations = [_conv('new', receiverId, minute: 9)];
    return _msg('sent', 9, content: content);
  }

  @override
  Stream<MessageModel> watchMessages(String conversationId) => msgLive.stream;

  @override
  Stream<ConversationModel> watchConversations(String userId) => convLive.stream;

  @override
  Future<void> markMessagesAsRead(String conversationId) async {}
}

void main() {
  late _FakeMessageRepo repo;
  late ProviderContainer container;

  setUp(() async {
    repo = _FakeMessageRepo();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthForTest()),
      messageRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
  });

  test('realtime sohbet güncellemesi listeyi yeniden çekmeden günceller ve sıralar', () async {
    repo.conversations = [_conv('a', 'p1', minute: 5), _conv('b', 'p2', minute: 3), _conv('c', 'p3')];
    container.listen(conversationsProvider, (_, _) {});
    await container.read(conversationsProvider.future);

    repo.convLive.add(_conv('b', 'p2', minute: 7)); // b'ye yeni mesaj
    repo.convLive.add(_conv('d', 'p4', minute: 1)); // yeni sohbet
    await pumpEventQueue();

    final ids = container.read(conversationsProvider).requireValue.map((c) => c.id);
    expect(ids, ['b', 'a', 'd', 'c']); // mesajsız sohbet en altta
    expect(repo.getConversationsCalls, 1);
  });

  test('ilk yükleme sürerken gelen mesaj kaybolmaz, tekrar gelen çoğalmaz', () async {
    repo.conversations = [_conv('a', 'peer', minute: 1)];
    container.listen(conversationsProvider, (_, _) {});
    await container.read(conversationsProvider.future);
    container.listen(activeChatProvider('peer'), (_, _) {});
    await pumpEventQueue();

    repo.msgLive.add(_msg('m3', 3)); // yükleme bitmeden
    await pumpEventQueue();
    repo.messagesLoad.complete([_msg('m1', 1), _msg('m2', 2)]);
    final state = await container.read(activeChatProvider('peer').future);
    expect(state.messages.map((m) => m.id), ['m1', 'm2', 'm3']);

    repo.msgLive.add(_msg('m2', 2, content: 'güncel')); // UPDATE eskiyi ezer
    repo.msgLive.add(_msg('m4', 4));
    await pumpEventQueue();
    final messages = container.read(activeChatProvider('peer')).requireValue.messages;
    expect(messages.map((m) => m.id), ['m1', 'm2', 'm3', 'm4']);
    expect(messages[1].content, 'güncel');
  });

  test('ilk mesaj gönderilince sohbet oluşur ve sohbet kanalına geçilir', () async {
    container.listen(conversationsProvider, (_, _) {});
    await container.read(conversationsProvider.future);
    container.listen(activeChatProvider('peer'), (_, _) {});
    expect((await container.read(activeChatProvider('peer').future)).conversationId, isNull);

    repo.messagesLoad.complete([_msg('sent', 9, content: 'merhaba')]);
    await container.read(activeChatProvider('peer').notifier).sendMessage('merhaba');
    await container.read(conversationsProvider.future);
    await pumpEventQueue();

    final state = await container.read(activeChatProvider('peer').future);
    expect(state.conversationId, 'new');
    expect(state.messages.map((m) => m.content), ['merhaba']);
  });

  test('yukarı kaydırınca daha eski sayfa başa eklenir, realtime kopya korunur', () async {
    repo.conversations = [_conv('a', 'peer', minute: 1)];
    repo.firstPageNext = (createdAt: DateTime.utc(2026), id: 'm1');
    container.listen(conversationsProvider, (_, _) {});
    await container.read(conversationsProvider.future);
    container.listen(activeChatProvider('peer'), (_, _) {});
    repo.messagesLoad.complete([_msg('m1', 1), _msg('m2', 2)]);
    await container.read(activeChatProvider('peer').future);
    final notifier = container.read(activeChatProvider('peer').notifier);
    expect(notifier.hasMore, isTrue);

    await notifier.loadMore();

    expect(repo.befores, [null, repo.firstPageNext]);
    final messages = container.read(activeChatProvider('peer')).requireValue.messages;
    expect(messages.map((m) => m.id), ['m0', 'm1', 'm2']);
    expect(notifier.hasMore, isFalse);
  });
}
