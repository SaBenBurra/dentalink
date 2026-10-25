import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_failures.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';
import 'post_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feed Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Feed mod: kronolojik veya algoritmik.
enum FeedMode { chronological, algorithmic }

class FeedNotifier extends AutoDisposeAsyncNotifier<List<PostModel>> {
  FeedMode _mode = FeedMode.chronological;
  final _pending = PostToggleQueue();

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

  /// Beğeniyi iyimser olarak çevirir; hata olursa geri alır.
  Future<void> toggleLike(String postId) => _toggle(postId, PostToggle.like);

  /// Kaydetmeyi iyimser olarak çevirir; hata olursa geri alır.
  Future<void> toggleBookmark(String postId) =>
      _toggle(postId, PostToggle.bookmark);

  /// Düzenlenen postu listeyi yeniden çekmeden günceller.
  void replacePost(PostModel updated) => patchPost(updated.id, (_) => updated);

  /// Listedeki tek postu günceller (detay ekranından senkronizasyon dahil).
  void patchPost(String postId, PostModel Function(PostModel) update) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData([for (final p in posts) p.id == postId ? update(p) : p]);
  }

  void removePost(String postId) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData([for (final p in posts) if (p.id != postId) p]);
  }

  /// Başka cihazda silinmiş post (NotFound) listeden düşer; hata yine
  /// fırlatılır ki UI kullanıcıya bildirsin.
  Future<void> _toggle(String postId, PostToggle toggle) async {
    try {
      await runPostToggle(
        ref,
        _pending,
        toggle,
        postId,
        current: () =>
            state.valueOrNull?.where((p) => p.id == postId).firstOrNull,
        patch: (update) => patchPost(postId, update),
      );
    } on NotFoundFailure {
      removePost(postId);
      rethrow;
    }
  }
}

final feedProvider =
    AsyncNotifierProvider.autoDispose<FeedNotifier, List<PostModel>>(() {
      return FeedNotifier();
    });
