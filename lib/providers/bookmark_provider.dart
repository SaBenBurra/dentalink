import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_model.dart';
import '../data/repositories/post_repository.dart';
import 'feed_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bookmark Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Kullanıcının kaydettiği gönderileri yöneten provider.
///
/// [PostRepository.getBookmarkedPosts] ile verileri çeker.
/// Toggle ve kaldırma işlemleri yerel state'i optimistik olarak günceller.
class BookmarkNotifier extends AutoDisposeAsyncNotifier<List<PostModel>> {
  @override
  Future<List<PostModel>> build() async {
    return _fetchBookmarks();
  }

  Future<List<PostModel>> _fetchBookmarks() {
    return ref.read(bookmarkRepositoryProvider).getBookmarkedPosts();
  }

  /// Listeyi yeniden yükler.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchBookmarks);
  }

  /// Bookmark'u kaldırır ve listeyi günceller.
  Future<void> removeBookmark(String postId) async {
    final posts = state.valueOrNull;
    if (posts == null) return;

    final repo = ref.read(bookmarkRepositoryProvider);
    await repo.unbookmarkPost(postId);

    // Optimistik: listeden çıkar
    final updated = posts.where((p) => p.id != postId).toList();
    state = AsyncData(updated);
  }

  /// Bookmark toggle eder (feed'den gelen senkronizasyon için).
  Future<void> toggleBookmark(String postId) async {
    final posts = state.valueOrNull;
    if (posts == null) return;

    final repo = ref.read(bookmarkRepositoryProvider);
    final isCurrentlyBookmarked = posts.any((p) => p.id == postId);

    if (isCurrentlyBookmarked) {
      await repo.unbookmarkPost(postId);
      final updated = posts.where((p) => p.id != postId).toList();
      state = AsyncData(updated);
    } else {
      final updatedPost = await repo.bookmarkPost(postId);
      state = AsyncData([updatedPost, ...posts]);
    }
  }
}

final bookmarkProvider =
    AsyncNotifierProvider.autoDispose<BookmarkNotifier, List<PostModel>>(() {
      return BookmarkNotifier();
    });
