import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/domain/entities/comment_entity.dart';
import 'package:dentlink/domain/repositories/comment_repository.dart';
import 'package:dentlink/providers/comment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CommentEntity _c(String id) => CommentEntity(
      id: id,
      postId: 'p1',
      userId: 'u',
      content: id,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

final _cursor = (createdAt: DateTime.utc(2024), id: 'c1');

/// İlk sayfa c1 + imleç; ikinci (son) sayfa bu ekranda eklenen c3'ü de içerir.
class _Repo implements CommentRepository {
  final afters = <PageCursor?>[];

  @override
  Future<PageResult<CommentEntity>> getComments(String postId,
      {PageCursor? after}) async {
    afters.add(after);
    return after == null
        ? (items: [_c('c1')], next: _cursor)
        : (items: [_c('c2'), _c('c3')], next: null);
  }

  @override
  Future<CommentEntity> addComment(String postId, String content) async =>
      _c('c3');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('sonraki sayfa eklenirken bu ekranda eklenen yorum çift görünmez', () async {
    final repo = _Repo();
    final container = ProviderContainer(
      overrides: [commentRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(commentsProvider('p1'), (_, _) {});

    await container.read(commentsProvider('p1').future);
    final notifier = container.read(commentsProvider('p1').notifier);
    await notifier.addComment('c3');
    expect(container.read(commentsProvider('p1')).value!.map((c) => c.id), ['c1', 'c3']);

    await notifier.loadMore();

    expect(repo.afters, [null, _cursor]);
    expect(
      container.read(commentsProvider('p1')).value!.map((c) => c.id),
      ['c1', 'c2', 'c3'],
    );
    expect(notifier.hasMore, isFalse);
  });
}
