import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_model.dart';
import 'feed_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tek Post Detay Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Belirli bir postun detayını getirir.
/// postRepositoryProvider'ı paylaşır — ayrı bir repository provider'a gerek yok.
final postDetailProvider = AutoDisposeFutureProvider.family<PostModel, String>(
  (ref, postId) async {
    return ref.read(postRepositoryProvider).getPostById(postId);
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Kullanıcı Postları Provider
// ─────────────────────────────────────────────────────────────────────────────

final userPostsProvider =
    AutoDisposeFutureProvider.family<List<PostModel>, String>(
  (ref, userId) async {
    return ref.read(postRepositoryProvider).getPostsByUser(userId);
  },
);

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
