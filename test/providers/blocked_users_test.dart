import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/moderation_repository.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/providers/moderation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

UserModel _user(String id) => UserModel(
      id: id,
      fullName: id,
      username: id,
      title: UserTitle.disHekimi,
      createdAt: DateTime(2024),
    );

class _ModerationRepo implements ModerationRepository {
  bool fail = false;
  final unblocked = <String>[];

  @override
  Future<List<UserModel>> getBlockedUsers() async => [_user('a'), _user('b'), _user('c')];

  @override
  Future<void> unblockUser(String userId) async {
    if (fail) throw const NetworkFailure();
    unblocked.add(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late _ModerationRepo repo;

  setUp(() async {
    repo = _ModerationRepo();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthForTest()),
      moderationRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    container.listen(blockedUsersProvider, (_, _) {});
    await container.read(blockedUsersProvider.future);
  });

  List<String> ids() =>
      container.read(blockedUsersProvider).requireValue.map((u) => u.id).toList();

  test('engeli kaldırınca kişi listeden çıkar', () async {
    await container.read(blockedUsersProvider.notifier).unblock('b');
    expect(ids(), ['a', 'c']);
    expect(repo.unblocked, ['b']);
  });

  test('hata olursa kişi eski yerine döner', () async {
    repo.fail = true;
    await expectLater(
      container.read(blockedUsersProvider.notifier).unblock('b'),
      throwsA(isA<NetworkFailure>()),
    );
    expect(ids(), ['a', 'b', 'c']);
  });

  test('çıkış yapınca liste boşalır (kural 7)', () async {
    await container.read(authProvider.notifier).signOut();
    expect(await container.read(blockedUsersProvider.future), isEmpty);
  });
}
