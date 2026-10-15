import 'dart:async';

import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/notification_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/notification_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

final _actor = UserModel(
  id: 'actor',
  fullName: 'Actor',
  username: 'actor',
  title: UserTitle.disHekimi,
  createdAt: DateTime(2026),
);

NotificationModel _n(String id, {bool isRead = false}) => NotificationModel(
      id: id,
      type: NotificationType.like,
      actor: _actor,
      isRead: isRead,
      createdAt: DateTime(2026),
    );

class _FakeNotificationRepo implements NotificationRepository {
  final live = StreamController<NotificationModel>.broadcast();
  List<NotificationModel> initial = [_n('1')];
  bool failWrites = false;
  String? watchedUserId;

  @override
  Future<List<NotificationModel>> getNotifications() async => initial;

  @override
  Stream<NotificationModel> watchNew(String userId) {
    watchedUserId = userId;
    return live.stream;
  }

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<void> markAllRead() async {
    if (failWrites) throw const NetworkFailure();
  }

  @override
  Future<void> markRead(String notificationId) async {
    if (failWrites) throw const NetworkFailure();
  }
}

void main() {
  late _FakeNotificationRepo repo;
  late ProviderContainer container;

  setUp(() async {
    repo = _FakeNotificationRepo();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthForTest()),
      notificationRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    container.listen(notificationsProvider, (_, _) {});
    await container.read(notificationsProvider.future);
  });

  List<NotificationModel> list() => container.read(notificationsProvider).requireValue;

  test('realtime ile gelen bildirim başa eklenir, tekrar gelirse çoğalmaz', () async {
    expect(repo.watchedUserId, 'mock_test_user_id');

    repo.live.add(_n('2'));
    repo.live.add(_n('2'));
    await Future<void>.delayed(Duration.zero);

    expect(list().map((n) => n.id), ['2', '1']);
    expect(container.read(unreadNotificationCountProvider), 2);
  });

  test('markRead hata verirse okunmamışa geri döner (BUG-23)', () async {
    repo.failWrites = true;

    await expectLater(
      container.read(notificationsProvider.notifier).markRead('1'),
      throwsA(isA<NetworkFailure>()),
    );

    expect(list().single.isRead, isFalse);
    expect(container.read(unreadNotificationCountProvider), 1);
  });

  test('markAllRead başarılıysa rozet sıfırlanır', () async {
    await container.read(notificationsProvider.notifier).markAllRead();
    expect(container.read(unreadNotificationCountProvider), 0);
  });

  test('çıkış yapınca bildirimler temizlenir', () async {
    await container.read(authProvider.notifier).signOut();
    expect(await container.read(notificationsProvider.future), isEmpty);
  });
}
