import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_model.dart';
import 'feed_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tek Post Detay Provider
// ─────────────────────────────────────────────────────────────────────────────

class PostDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<PostModel, String> {
  @override
  Future<PostModel> build(String arg) async {
    return ref.read(postRepositoryProvider).getPostById(arg);
  }

  Future<void> toggleLike() async {
    final post = state.valueOrNull;
    if (post == null) return;
    final repo = ref.read(postRepositoryProvider);
    final updated = post.isLiked
        ? await repo.unlikePost(arg)
        : await repo.likePost(arg);
    state = AsyncData(updated);
    ref.invalidate(feedProvider);
  }

  Future<void> toggleBookmark() async {
    final post = state.valueOrNull;
    if (post == null) return;
    final repo = ref.read(postRepositoryProvider);
    final updated = post.isBookmarked
        ? await repo.unbookmarkPost(arg)
        : await repo.bookmarkPost(arg);
    state = AsyncData(updated);
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
      return ref.read(postRepositoryProvider).getPostsByUser(userId);
    });

// ─────────────────────────────────────────────────────────────────────────────
// Kaydedilenler Provider
// ─────────────────────────────────────────────────────────────────────────────

class BookmarksNotifier extends AutoDisposeAsyncNotifier<List<PostModel>> {
  @override
  Future<List<PostModel>> build() async {
    return ref.read(postRepositoryProvider).getBookmarkedPosts();
  }

  Future<void> removeBookmark(String postId) async {
    final posts = state.valueOrNull;
    if (posts == null) return;
    await ref.read(postRepositoryProvider).unbookmarkPost(postId);
    state = AsyncData(posts.where((p) => p.id != postId).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(postRepositoryProvider).getBookmarkedPosts(),
    );
  }
}

final bookmarksProvider =
    AsyncNotifierProvider.autoDispose<BookmarksNotifier, List<PostModel>>(() {
      return BookmarksNotifier();
    });
