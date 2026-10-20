import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_failures.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';
import 'feed_provider.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Tek Post Detay Provider
// ─────────────────────────────────────────────────────────────────────────────

class PostDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<PostModel, String> {
  @override
  Future<PostModel> build(String arg) async {
    return ref.read(feedRepositoryProvider).getPostById(arg);
  }

  Future<void> toggleLike() => _update((post) {
        final repo = ref.read(postActionRepositoryProvider);
        return post.isLiked ? repo.unlikePost(arg) : repo.likePost(arg);
      });

  Future<void> toggleBookmark() => _update((post) {
        final repo = ref.read(bookmarkRepositoryProvider);
        return post.isBookmarked
            ? repo.unbookmarkPost(arg)
            : repo.bookmarkPost(arg);
      });

  /// Post başka cihazda silinmişse ekran "bulunamadı" durumuna geçer;
  /// diğer hatalar UI'ın göstermesi için fırlatılır.
  Future<void> _update(Future<PostModel> Function(PostModel post) action) async {
    final post = state.valueOrNull;
    if (post == null) return;
    try {
      state = AsyncData(await action(post));
    } on NotFoundFailure catch (e, st) {
      state = AsyncError(e, st);
    }
    ref.invalidate(feedProvider);
  }
}

final postDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PostDetailNotifier, PostModel, String>(() {
      return PostDetailNotifier();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Kullanıcı Postları Provider
// ─────────────────────────────────────────────────────────────────────────────

final userPostsProvider =
    AutoDisposeFutureProvider.family<List<PostModel>, String>((
      ref,
      userId,
    ) async {
      return ref.read(feedRepositoryProvider).getPostsByUser(userId);
    });

