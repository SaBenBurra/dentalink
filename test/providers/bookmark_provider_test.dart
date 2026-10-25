import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/providers/bookmark_provider.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

QuestionPostModel _post(String id) => QuestionPostModel(
      id: id,
      userId: 'a',
      title: 't$id',
      content: 'c',
      likeCount: 5,
      isBookmarked: true,
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
  final posts = [_post('p1'), _post('p2'), _post('p3')];

  @override
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) async =>
      (items: posts, next: null);

  @override
  Future<PageResult<PostModel>> getBookmarkedPosts({PageCursor? before}) async =>
      (items: posts, next: null);

  @override
  Future<PostModel> likePost(String postId) async =>
      posts.firstWhere((p) => p.id == postId).copyWith(isLiked: true, likeCount: 6);

  @override
  Future<PostModel> unbookmarkPost(String postId) async =>
      posts.firstWhere((p) => p.id == postId).copyWith(isBookmarked: false);

  @override
  Future<PostModel> bookmarkPost(String postId) async =>
      posts.firstWhere((p) => p.id == postId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    final repo = _Repo();
    container = ProviderContainer(overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      bookmarkRepositoryProvider.overrideWithValue(repo),
      postActionRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    container.listen(feedProvider, (_, _) {});
    container.listen(bookmarkProvider, (_, _) {});
    await container.read(feedProvider.future);
    await container.read(bookmarkProvider.future);
  });

  List<PostModel> bookmarks() => container.read(bookmarkProvider).value!;
  PostModel feedPost(String id) =>
      container.read(feedProvider).value!.firstWhere((p) => p.id == id);

  test('kaydedilenlerdeki beğeni çalışır ve feed\'e yansır (BUG-24)', () async {
    await container.read(bookmarkProvider.notifier).toggleLike('p2');

    expect(bookmarks()[1].isLiked, isTrue);
    expect(feedPost('p2').isLiked, isTrue);
  });

  test('kaldırılan kayıt geri alınınca eski sırasına döner (BUG-24)', () async {
    final notifier = container.read(bookmarkProvider.notifier);
    final p2 = bookmarks()[1];

    await notifier.removeBookmark('p2');
    expect(bookmarks().map((p) => p.id), ['p1', 'p3']);
    expect(feedPost('p2').isBookmarked, isFalse);

    await notifier.restoreBookmark(p2, 1);
    expect(bookmarks().map((p) => p.id), ['p1', 'p2', 'p3']);
    expect(feedPost('p2').isBookmarked, isTrue);
  });
}
