import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/paging.dart';
import '../data/models/post_model.dart';
import '../core/error/app_failures.dart';
import '../data/providers/repository_providers.dart';
import 'feed_provider.dart';
import 'post_toggle.dart';
import 'search_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bookmark Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Kullanıcının kaydettiği gönderileri yöneten provider.
///
/// [PostRepository.getBookmarkedPosts] ile verileri çeker.
/// Toggle ve kaldırma işlemleri yerel state'i optimistik olarak günceller.
class BookmarkNotifier extends AutoDisposeAsyncNotifier<List<PostModel>> {
  final _pager = Pager<PostModel>();
  final _pending = PostToggleQueue();

  bool get hasMore => _pager.hasMore;

  @override
  Future<List<PostModel>> build() async {
    return _fetchBookmarks();
  }

  Future<List<PostModel>> _fetchBookmarks() async => _pager
      .first(await ref.read(bookmarkRepositoryProvider).getBookmarkedPosts());

  /// Listeyi yeniden yükler.
  Future<void> refresh() async {
    _pager.reset();
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchBookmarks);
  }

  Future<void> loadMore() => _pager.loadMore(
        (before) => ref
            .read(bookmarkRepositoryProvider)
            .getBookmarkedPosts(before: before),
        (items) {
          final posts = state.valueOrNull;
          if (posts != null) state = AsyncData([...posts, ...items]);
        },
      );

  /// Bookmark'u kaldırır ve listeyi günceller.
  Future<void> removeBookmark(String postId) async {
    final posts = state.valueOrNull;
    if (posts == null) return;

    // Önce listeden çıkar (await'ten ÖNCE): Dismissible kaydırıldığı anda
    // ağaçtan kalkmalı, aksi halde "dismissed Dismissible" assertion'ı çıkar.
    state = AsyncData(posts.where((p) => p.id != postId).toList());

    try {
      final server =
          await ref.read(bookmarkRepositoryProvider).unbookmarkPost(postId);
      _syncOthers(postId, (p) => PostToggle.bookmark.copyFields(p, server));
    } catch (_) {
      state = AsyncData(posts); // Rollback
      rethrow;
    }
  }

  /// "Geri Al": kaydı geri ekler ve postu eski sırasına koyar.
  Future<void> restoreBookmark(PostModel post, int index) async {
    final server = await ref.read(bookmarkRepositoryProvider).bookmarkPost(post.id);
    _syncOthers(post.id, (p) => PostToggle.bookmark.copyFields(p, server));
    final posts = state.valueOrNull;
    if (posts == null || posts.any((p) => p.id == post.id)) return;
    state = AsyncData([...posts]..insert(index.clamp(0, posts.length), server));
  }

  /// İyimser beğeni; feed ve aramadaki aynı post yeniden çekilmeden güncellenir.
  Future<void> toggleLike(String postId) async {
    try {
      final server = await runPostToggle(
        ref,
        _pending,
        PostToggle.like,
        postId,
        current: () => state.valueOrNull?.where((p) => p.id == postId).firstOrNull,
        patch: (update) {
          final posts = state.valueOrNull;
          if (posts == null) return;
          state = AsyncData([for (final p in posts) p.id == postId ? update(p) : p]);
        },
      );
      if (server != null) {
        _syncOthers(postId, (p) => PostToggle.like.copyFields(p, server));
      }
    } on NotFoundFailure {
      final posts = state.valueOrNull;
      if (posts != null) state = AsyncData(posts.where((p) => p.id != postId).toList());
      rethrow;
    }
  }

  void _syncOthers(String postId, PostModel Function(PostModel) update) {
    if (ref.exists(feedProvider)) ref.read(feedProvider.notifier).patchPost(postId, update);
    if (ref.exists(searchProvider)) {
      ref.read(searchProvider.notifier).patchPost(postId, update);
    }
  }
}

final bookmarkProvider =
    AsyncNotifierProvider.autoDispose<BookmarkNotifier, List<PostModel>>(() {
      return BookmarkNotifier();
    });
