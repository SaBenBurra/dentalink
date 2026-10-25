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

/// Kesişim DB'de (get_mutual_followers); burada yalnızca istenen profiller kaydedilir.
class _FollowRepo implements FollowRepository {
  final asked = <String>[];

  @override
  Future<MutualFollowers> getMutualFollowers(String userId, {int limit = 3}) async {
    asked.add(userId);
    return (users: [_user('y')], total: 4);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late _FollowRepo repo;

  setUp(() async {
    repo = _FollowRepo();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthForTest()),
      followRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
  });

  Future<MutualFollowers> mutual(String userId) {
    container.listen(mutualFollowersProvider(userId), (_, _) {});
    return container.read(mutualFollowersProvider(userId).future);
  }

  test('başka profilde DB sonucu (ilk kişiler + toplam) döner', () async {
    final result = await mutual('p');
    expect(result.users.map((u) => u.id), ['y']);
    expect(result.total, 4);
  });

  test('kendi profilimde boş ve istek gitmez', () async {
    final result = await mutual(_me);
    expect(result.users, isEmpty);
    expect(result.total, 0);
    expect(repo.asked, isEmpty);
  });
}
