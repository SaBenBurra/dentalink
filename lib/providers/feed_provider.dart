import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_failures.dart';
import '../core/utils/paging.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';
import 'connectivity_provider.dart';
import 'post_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feed Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Kronolojik feed; sayfalar [loadMore] ile eklenir.
class FeedNotifier extends AutoDisposeAsyncNotifier<List<PostModel>> {
  final _pending = PostToggleQueue();
  final _pager = Pager<PostModel>();

  bool get hasMore => _pager.hasMore;

  @override
  Future<List<PostModel>> build() async {
    listenReconnect(ref, () {
      if (state.hasError) ref.invalidateSelf();
    });
    return _fetchFirst();
  }

  Future<List<PostModel>> _fetchFirst() async =>
      _pager.first(await ref.read(feedRepositoryProvider).getFeed());

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirst);
  }

  Future<void> loadMore() => _pager.loadMore(
        (before) => ref.read(feedRepositoryProvider).getFeed(before: before),
        (items) {
          final posts = state.valueOrNull;
          if (posts != null) state = AsyncData([...posts, ...items]);
        },
      );

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
