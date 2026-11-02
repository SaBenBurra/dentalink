import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/app_failures.dart';
import '../core/utils/paging.dart';
import '../data/models/case_treatment.dart';
import '../data/models/enums.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';
import 'post_toggle.dart';

class TreatmentArchiveState {
  /// true: en yeni önce; false: popülerlik (035).
  final bool recent;
  final AsyncValue<List<PostModel>> posts;
  final bool hasMore;

  const TreatmentArchiveState({
    this.recent = true,
    this.posts = const AsyncLoading(),
    this.hasMore = false,
  });

  TreatmentArchiveState copyWith({
    bool? recent,
    AsyncValue<List<PostModel>>? posts,
    bool? hasMore,
  }) => TreatmentArchiveState(
    recent: recent ?? this.recent,
    posts: posts ?? this.posts,
    hasMore: hasMore ?? this.hasMore,
  );
}

/// Açık arşivlerin slug'ları: [patchPostCopies] family'yi gezemediği için.
final openArchivesProvider = Provider<Set<String>>((ref) => {});

/// Bir tedavinin vakaları (`/treatment/:slug`), offset sayfalı.
class TreatmentArchiveNotifier
    extends AutoDisposeFamilyNotifier<TreatmentArchiveState, String> {
  int _requestId = 0;
  final _pending = PostToggleQueue();
  DateTime _now = DateTime.now();
  int _offset = 0;
  Future<void>? _loadingMore;

  @override
  TreatmentArchiveState build(String arg) {
    final open = ref.read(openArchivesProvider)..add(arg);
    ref.onDispose(() => open.remove(arg));
    Future.microtask(_reload);
    return const TreatmentArchiveState();
  }

  void setRecent(bool recent) {
    if (recent == state.recent) return;
    state = state.copyWith(recent: recent);
    _reload();
  }

  Future<void> refresh() => _reload();

  Future<List<PostModel>> _fetch(int offset) => ref
      .read(searchRepositoryProvider)
      .popularPosts(
        treatment: arg,
        recent: state.recent,
        now: _now,
        offset: offset,
      );

  Future<void> _reload() async {
    final requestId = ++_requestId;
    _now = DateTime.now();
    _offset = 0;
    _loadingMore = null;
    state = state.copyWith(posts: const AsyncLoading(), hasMore: false);
    final posts = await AsyncValue.guard(() => _fetch(0));
    if (requestId != _requestId) return;
    _offset = pageSize;
    state = state.copyWith(
      posts: posts,
      hasMore: (posts.valueOrNull?.length ?? 0) >= pageSize,
    );
  }

  /// Sonraki sayfa; aynı anda gelen çağrılar aynı isteği bekler. Hata fırlatılır.
  Future<void> loadMore() {
    if (!state.hasMore) return Future.value();
    return _loadingMore ??= _loadMore();
  }

  Future<void> _loadMore() async {
    final requestId = _requestId;
    try {
      final items = await _fetch(_offset);
      if (requestId != _requestId) return;
      _offset += pageSize;
      // Sayaç değişiminde offset kayarsa aynı post iki kez gelmesin.
      final seen = {for (final p in state.posts.valueOrNull ?? []) p.id};
      state = state.copyWith(
        posts: AsyncData([
          ...?state.posts.valueOrNull,
          for (final p in items)
            if (!seen.contains(p.id)) p,
        ]),
        hasMore: items.length >= pageSize,
      );
    } finally {
      if (requestId == _requestId) _loadingMore = null;
    }
  }

  void patchPost(String postId, PostModel Function(PostModel) update) {
    final posts = state.posts.valueOrNull;
    if (posts == null) return;
    state = state.copyWith(
      posts: AsyncData([for (final p in posts) p.id == postId ? update(p) : p]),
    );
  }

  void removePost(String postId) {
    final posts = state.posts.valueOrNull;
    if (posts == null) return;
    state = state.copyWith(
      posts: AsyncData([
        for (final p in posts)
          if (p.id != postId) p,
      ]),
    );
  }

  Future<void> toggleLike(String postId) => _toggle(postId, PostToggle.like);

  Future<void> toggleBookmark(String postId) =>
      _toggle(postId, PostToggle.bookmark);

  Future<void> _toggle(String postId, PostToggle toggle) async {
    try {
      await runPostToggle(
        ref,
        _pending,
        toggle,
        postId,
        current: () =>
            state.posts.valueOrNull?.where((p) => p.id == postId).firstOrNull,
        patch: (update) => patchPost(postId, update),
      );
    } on NotFoundFailure {
      removePost(postId);
      rethrow;
    }
  }
}

final treatmentArchiveProvider = NotifierProvider.autoDispose
    .family<TreatmentArchiveNotifier, TreatmentArchiveState, String>(
      TreatmentArchiveNotifier.new,
    );

/// Arşiv başlığı: ad, branş, vaka sayısı. Kullanıcı tedavisi birden çok
/// branşta geçebilir; en çok vakası olan gelir. Yoksa null.
final treatmentInfoProvider = FutureProvider.autoDispose
    .family<CaseTreatment?, String>((ref, slug) async {
      final rows = await ref
          .watch(searchRepositoryProvider)
          .listTreatments(slug: slug, limit: 10);
      return rows.firstOrNull;
    });

/// Keşfet'te seçili branşın tedavileri (vaka sayılarıyla).
final branchTreatmentsProvider = FutureProvider.autoDispose
    .family<List<CaseTreatment>, DentalBranch>(
      (ref, branch) =>
          ref.watch(searchRepositoryProvider).listTreatments(branch: branch),
    );

/// Keşfet metin aramasının en üstündeki tedaviler (en fazla 3, slug başına bir).
final treatmentSearchProvider = FutureProvider.autoDispose
    .family<List<CaseTreatment>, String>((ref, query) async {
      final rows = await ref
          .watch(searchRepositoryProvider)
          .listTreatments(query: query, limit: 6);
      final seen = <String>{};
      return [
        for (final t in rows)
          if (t.caseCount > 0 && seen.add(t.slug)) t,
      ].take(3).toList();
    });

/// Post sayfasındaki "Benzer vakalar".
final relatedCasesProvider = FutureProvider.autoDispose
    .family<List<PostModel>, String>(
      (ref, postId) => ref.watch(searchRepositoryProvider).relatedCases(postId),
    );
