import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_model.dart';
import '../data/repositories/mock_post_repository.dart';
import '../data/repositories/post_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ─────────────────────────────────────────────────────────────────────────────

final _basePostRepositoryProvider = Provider<PostRepository>((ref) {
  return MockPostRepository();
});

final feedRepositoryProvider = Provider<IFeedRepository>((ref) => ref.watch(_basePostRepositoryProvider));
final bookmarkRepositoryProvider = Provider<IBookmarkRepository>((ref) => ref.watch(_basePostRepositoryProvider));
final searchRepositoryProvider = Provider<ISearchRepository>((ref) => ref.watch(_basePostRepositoryProvider));
final postActionRepositoryProvider = Provider<IPostActionRepository>((ref) => ref.watch(_basePostRepositoryProvider));

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
  Future<void> toggleLike(String postId) async {
    final posts = state.valueOrNull;
    if (posts == null) return;

    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = posts[idx];
    final repo = ref.read(postActionRepositoryProvider);

    final updated = post.isLiked
        ? await repo.unlikePost(postId)
        : await repo.likePost(postId);

    final newList = List<PostModel>.from(posts);
    newList[idx] = updated;
    state = AsyncData(newList);
  }

  /// Bookmark toggle eder ve feed state'ini günceller.
  Future<void> toggleBookmark(String postId) async {
    final posts = state.valueOrNull;
    if (posts == null) return;

    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = posts[idx];
    final repo = ref.read(bookmarkRepositoryProvider);

    final updated = post.isBookmarked
        ? await repo.unbookmarkPost(postId)
        : await repo.bookmarkPost(postId);

    final newList = List<PostModel>.from(posts);
    newList[idx] = updated;
    state = AsyncData(newList);
  }
}

final feedProvider =
    AsyncNotifierProvider.autoDispose<FeedNotifier, List<PostModel>>(() {
      return FeedNotifier();
    });
