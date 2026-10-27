import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/data/models/comment_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/repositories/comment_repository.dart';
import 'package:dentlink/providers/comment_provider.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:dentlink/providers/post_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _post = QuestionPostModel(
  id: 'p1',
  userId: 'a',
  title: 't',
  content: 'c',
  commentCount: 2,
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

class _PostRepo implements PostRepository {
  int feedCalls = 0;

  @override
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) async {
    feedCalls++;
    return (items: [_post], next: null);
  }

  @override
  Future<PostModel> getPostById(String id) async => _post;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CommentRepo implements CommentRepository {
  final unmarked = <String>[];

  @override
  Future<void> unmarkBestAnswer(String commentId) async => unmarked.add(commentId);

  @override
  Future<PageResult<CommentModel>> getComments(String postId,
          {PageCursor? after}) async =>
      (items: <CommentModel>[], next: null);

  @override
  Future<CommentModel> addComment(String postId, String content,
          {String? parentId}) async =>
      CommentModel(
        id: 'c1',
        postId: postId,
        userId: 'b',
        content: content,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('yorum eklenince detay ve feed sayacı yeniden çekmeden artar', () async {
    final repo = _PostRepo();
    final container = ProviderContainer(overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      commentRepositoryProvider.overrideWithValue(_CommentRepo()),
    ]);
    addTearDown(container.dispose);
    container.listen(feedProvider, (_, _) {});
    container.listen(postDetailProvider('p1'), (_, _) {});
    container.listen(commentsProvider('p1'), (_, _) {});
    await container.read(feedProvider.future);
    await container.read(postDetailProvider('p1').future);
    await container.read(commentsProvider('p1').future);

    await container.read(commentsProvider('p1').notifier).addComment('merhaba');

    expect(container.read(commentsProvider('p1')).value, hasLength(1));
    expect(container.read(postDetailProvider('p1')).value!.commentCount, 3);
    expect(container.read(feedProvider).value!.single.commentCount, 3);
    expect(repo.feedCalls, 1);
  });

  test('en iyi cevap seçimini kaldırma RPC çağırır', () async {
    final comments = _CommentRepo();
    final repo = _PostRepo();
    final container = ProviderContainer(overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      commentRepositoryProvider.overrideWithValue(comments),
    ]);
    addTearDown(container.dispose);
    container.listen(commentsProvider('p1'), (_, _) {});
    await container.read(commentsProvider('p1').future);

    await container.read(commentsProvider('p1').notifier).unmarkBestAnswer('c1');

    expect(comments.unmarked, ['c1']);
  });
}
