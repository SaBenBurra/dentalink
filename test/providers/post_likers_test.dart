import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user(String id) => UserModel(
  id: id,
  fullName: id,
  username: id,
  title: UserTitle.disHekimi,
  createdAt: DateTime(2024),
);

class _Repo implements PostRepository {
  final postIds = <String>[];

  @override
  Future<PageResult<UserModel>> getPostLikers(
    String postId, {
    PageCursor? before,
  }) async {
    postIds.add(postId);
    return before == null
        ? (items: [_user('a')], next: (createdAt: DateTime(2024), id: 'l1'))
        : (items: [_user('b')], next: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('beğenenler sayfalanır', () async {
    final repo = _Repo();
    final container = ProviderContainer(
      overrides: [postActionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final provider = postLikersProvider('p1');
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);

    expect((await container.read(provider.future)).single.id, 'a');
    await container.read(provider.notifier).loadMore();

    expect(container.read(provider).value!.map((u) => u.id), ['a', 'b']);
    expect(container.read(provider.notifier).hasMore, isFalse);
    expect(repo.postIds, ['p1', 'p1']);
  });
}
