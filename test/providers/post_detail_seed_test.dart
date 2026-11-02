import 'dart:async';

import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/providers/bookmark_provider.dart';
import 'package:dentlink/providers/post_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

QuestionPostModel _post({int likes = 0, bool liked = false}) =>
    QuestionPostModel(
      id: 'p1',
      userId: 'a',
      title: 't',
      content: 'c',
      likeCount: likes,
      isLiked: liked,
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

class _Repo implements PostRepository {
  /// Sunucu okuması elle tamamlanır: önce eldeki kopyanın gösterildiği görülsün.
  final fetch = Completer<PostModel>();

  @override
  Future<PostModel> getPostById(String id) => fetch.future;
  @override
  Future<PageResult<PostModel>> getPostsByUser(
    String userId, {
    PageCursor? before,
  }) async => (items: [_post()], next: null);
  @override
  Future<PageResult<PostModel>> getBookmarkedPosts({
    PageCursor? before,
  }) async => (items: [_post()], next: null);
  @override
  Future<PostModel> likePost(String postId) async =>
      _post(likes: 1, liked: true);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _Repo();
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(repo),
        postActionRepositoryProvider.overrideWithValue(repo),
        bookmarkRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'listeden gelen kopya ilk karede gösterilir, sonra sunucudaki gelir',
    () async {
      container.read(postSeedsProvider)['p1'] = _post();
      container.listen(postDetailProvider('p1'), (_, _) {});
      expect(container.read(postDetailProvider('p1')).value?.likeCount, 0);

      repo.fetch.complete(_post(likes: 7));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(postDetailProvider('p1')).value?.likeCount, 7);
      expect(container.read(postSeedsProvider), isEmpty);
    },
  );

  test('sunucuda post yoksa "bulunamadı" durumuna geçer', () async {
    container.read(postSeedsProvider)['p1'] = _post();
    container.listen(postDetailProvider('p1'), (_, _) {});
    repo.fetch.completeError(const NotFoundFailure());
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(postDetailProvider('p1')).error,
      isA<NotFoundFailure>(),
    );
  });

  test('detaydaki beğeni kaydedilenlere ve yazarın profiline yansır', () async {
    container.listen(bookmarkProvider, (_, _) {});
    container.listen(userPostsProvider('a'), (_, _) {});
    await container.read(bookmarkProvider.future);
    await container.read(userPostsProvider('a').future);
    container.read(postSeedsProvider)['p1'] = _post();
    container.listen(postDetailProvider('p1'), (_, _) {});

    await container.read(postDetailProvider('p1').notifier).toggleLike();

    expect(container.read(bookmarkProvider).value!.single.isLiked, isTrue);
    expect(container.read(userPostsProvider('a')).value!.single.likeCount, 1);
  });
}
