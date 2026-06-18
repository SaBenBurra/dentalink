import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/comment_model.dart';
import '../data/repositories/comment_repository.dart';
import '../data/repositories/mock_comment_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ─────────────────────────────────────────────────────────────────────────────

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return MockCommentRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Comments Notifier (post başına)
// ─────────────────────────────────────────────────────────────────────────────

class CommentsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CommentModel>, String> {
  @override
  Future<List<CommentModel>> build(String postId) async {
    return ref.read(commentRepositoryProvider).getComments(postId);
  }

  Future<void> addComment(String content) async {
    final repo = ref.read(commentRepositoryProvider);
    final newComment = await repo.addComment(arg, content);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, newComment]);
  }

  Future<void> markBestAnswer(String commentId) async {
    final repo = ref.read(commentRepositoryProvider);
    await repo.markBestAnswer(commentId);
    // Listeyi yenile — sıralama değişebilir.
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repo.getComments(arg),
    );
  }

  Future<void> toggleLike(String commentId) async {
    final comments = state.valueOrNull;
    if (comments == null) return;

    final idx = comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;

    final comment = comments[idx];
    final repo = ref.read(commentRepositoryProvider);

    final updated = comment.isLiked
        ? await repo.unlikeComment(commentId)
        : await repo.likeComment(commentId);

    final newList = List<CommentModel>.from(comments);
    newList[idx] = updated;
    state = AsyncData(newList);
  }
}

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsNotifier, List<CommentModel>, String>(() {
  return CommentsNotifier();
});
