import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:dentlink/providers/post_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _post = QuestionPostModel(
  id: 'p1',
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

/// Post ekranda açıkken başka cihazda silinmiş: okuma çalışır, beğeni NotFound.
class _DeletedPostRepo implements PostRepository {
  @override
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) async =>
      (items: [_post], next: null);
  @override
  Future<PostModel> getPostById(String id) async => _post;
  @override
  Future<PostModel> likePost(String postId) async => throw const NotFoundFailure();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;

  setUp(() {
    final repo = _DeletedPostRepo();
    container = ProviderContainer(overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      postActionRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('detayda silinmiş postu beğenmek ekranı "bulunamadı" durumuna geçirir', () async {
    container.listen(postDetailProvider('p1'), (_, _) {});
    await container.read(postDetailProvider('p1').future);

    await container.read(postDetailProvider('p1').notifier).toggleLike();

    expect(container.read(postDetailProvider('p1')).error, isA<NotFoundFailure>());
  });

  test('feed\'de silinmiş postu beğenmek onu listeden çıkarır ve hatayı bildirir', () async {
    container.listen(feedProvider, (_, _) {});
    await container.read(feedProvider.future);

    await expectLater(
      container.read(feedProvider.notifier).toggleLike('p1'),
      throwsA(isA<NotFoundFailure>()),
    );
    expect(container.read(feedProvider).value, isEmpty);
  });
}
