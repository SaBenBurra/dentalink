import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_failures.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feed Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Feed mod: kronolojik veya algoritmik.
enum FeedMode { chronological, algorithmic }

class FeedNotifier extends AutoDisposeAsyncNotifier<List<PostModel>> {
  FeedMode _mode = FeedMode.chronological;

  FeedMode get mode => _mode;

  @override
  Future<List<PostModel>> build() async {
    return _fetchFeed();
  }

  Future<List<PostModel>> _fetchFeed() {
    return ref
        .read(feedRepositoryProvider)
        .getFeed(chronological: _mode == FeedMode.chronological);
  }

  Future<void> switchMode(FeedMode mode) async {
    _mode = mode;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFeed);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFeed);
  }

  /// Post beğenisini toggle eder ve feed state'ini günceller.
  Future<void> toggleLike(String postId) => _update(postId, (post) {
        final repo = ref.read(postActionRepositoryProvider);
        return post.isLiked ? repo.unlikePost(postId) : repo.likePost(postId);
      });

  /// Bookmark toggle eder ve feed state'ini günceller.
  Future<void> toggleBookmark(String postId) => _update(postId, (post) {
        final repo = ref.read(bookmarkRepositoryProvider);
        return post.isBookmarked
            ? repo.unbookmarkPost(postId)
            : repo.bookmarkPost(postId);
      });

  /// Başka cihazda silinmiş post (NotFound) listeden düşer; hata yine
  /// fırlatılır ki UI kullanıcıya bildirsin.
  Future<void> _update(
    String postId,
    Future<PostModel> Function(PostModel post) action,
  ) async {
    final post = state.valueOrNull?.where((p) => p.id == postId).firstOrNull;
    if (post == null) return;
    try {
      final updated = await action(post);
      state = AsyncData([
        for (final p in state.valueOrNull ?? const <PostModel>[])
          p.id == postId ? updated : p,
      ]);
    } on NotFoundFailure {
      state = AsyncData([
        for (final p in state.valueOrNull ?? const <PostModel>[])
          if (p.id != postId) p,
      ]);
      rethrow;
    }
  }
}

final feedProvider =
    AsyncNotifierProvider.autoDispose<FeedNotifier, List<PostModel>>(() {
      return FeedNotifier();
    });
