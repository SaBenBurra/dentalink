import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PostModel _post(String id) => QuestionPostModel(
      id: id,
      userId: 'a',
      title: 't',
      content: 'c',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      author: UserModel(
        id: 'a',
        fullName: 'A',
        username: 'a',
        title: UserTitle.disHekimi,
        createdAt: DateTime(2024),
      ),
    );

final _cursor = (createdAt: DateTime.utc(2024), id: 'p1');

/// İki sayfalık feed: ilk sayfa imleç döner, ikinci son sayfadır.
class _TwoPageRepo implements PostRepository {
  final befores = <PageCursor?>[];

  @override
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) async {
    befores.add(before);
    return before == null
        ? (items: [_post('p1')], next: _cursor)
        : (items: [_post('p2')], next: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('loadMore ikinci sayfayı imleçle çekip ekler; sonra hasMore false', () async {
    final repo = _TwoPageRepo();
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(feedProvider, (_, _) {});

    await container.read(feedProvider.future);
    final notifier = container.read(feedProvider.notifier);
    expect(notifier.hasMore, isTrue);

    await notifier.loadMore();

    expect(repo.befores, [null, _cursor]);
    expect(container.read(feedProvider).value!.map((p) => p.id), ['p1', 'p2']);
    expect(notifier.hasMore, isFalse);

    // Yenileme ilk sayfaya döner ve imleci yeniden kurar.
    await notifier.refresh();
    expect(container.read(feedProvider).value!.map((p) => p.id), ['p1']);
    expect(notifier.hasMore, isTrue);
  });
}
