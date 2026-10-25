import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/follow_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

const _me = 'mock_test_user_id';

UserModel _user(String id) => UserModel(
      id: id,
      fullName: id,
      username: id,
      title: UserTitle.disHekimi,
      createdAt: DateTime(2024),
    );

/// 'p' profilini x, y, z takip ediyor; oturumdaki kullanıcı yalnızca y'yi takip ediyor.
class _FollowRepo implements FollowRepository {
  @override
  Future<List<UserModel>> getFollowers(String userId) async =>
      [_user('x'), _user('y'), _user('z')];

  @override
  Future<Set<String>> getFollowedUserIds(List<String> userIds) async =>
      {'y'}.intersection(userIds.toSet());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthForTest()),
      followRepositoryProvider.overrideWithValue(_FollowRepo()),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
  });

  Future<List<String>> mutual(String userId) async {
    container.listen(mutualFollowersProvider(userId), (_, _) {});
    final users = await container.read(mutualFollowersProvider(userId).future);
    return [for (final u in users) u.id];
  }

  test('yalnızca benim de takip ettiğim takipçiler döner', () async {
    expect(await mutual('p'), ['y']);
  });

  test('kendi profilimde boş', () async {
    expect(await mutual(_me), isEmpty);
  });
}
