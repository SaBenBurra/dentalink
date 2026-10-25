import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/enums.dart';
import '../core/error/app_failures.dart';
import '../core/utils/paging.dart';
import '../data/models/post_model.dart';
import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';
import 'post_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Search State
// ─────────────────────────────────────────────────────────────────────────────

class SearchState {
  final String query;
  final DentalBranch? branchFilter;
  final PostType? typeFilter;
  final AsyncValue<List<PostModel>> postResults;
  final AsyncValue<List<UserModel>> userResults;

  const SearchState({
    this.query = '',
    this.branchFilter,
    this.typeFilter,
    this.postResults = const AsyncData([]),
    this.userResults = const AsyncData([]),
  });

  SearchState copyWith({
    String? query,
    // ValueGetter: filtreyi null'a (Tümü) çekebilmek için; '??' ile mümkün değil.
    DentalBranch? Function()? branchFilter,
    PostType? Function()? typeFilter,
    AsyncValue<List<PostModel>>? postResults,
    AsyncValue<List<UserModel>>? userResults,
  }) {
    return SearchState(
      query: query ?? this.query,
      branchFilter: branchFilter != null ? branchFilter() : this.branchFilter,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      postResults: postResults ?? this.postResults,
      userResults: userResults ?? this.userResults,
    );
  }

  bool get isEmpty => query.isEmpty;
  bool get hasResults =>
      (postResults.valueOrNull?.isNotEmpty ?? false) ||
      (userResults.valueOrNull?.isNotEmpty ?? false);
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Notifier
// ─────────────────────────────────────────────────────────────────────────────

class SearchNotifier extends AutoDisposeNotifier<SearchState> {
  /// Yalnızca en son isteğin sonucu yazılır; yavaş eski bir yanıt yenisini ezmez.
  int _requestId = 0;
  final _pending = PostToggleQueue();
  final _pager = Pager<PostModel>();

  bool get hasMore => _pager.hasMore;

  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    final requestId = ++_requestId;
    _pager.reset();
    if (query.trim().isEmpty) {
      state = SearchState(
        branchFilter: state.branchFilter,
        typeFilter: state.typeFilter,
      );
      return;
    }

    state = state.copyWith(
      query: query,
      postResults: const AsyncLoading(),
      userResults: const AsyncLoading(),
    );

    final postRepo = ref.read(searchRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    // Post ve kullanıcı aramasını paralel çalıştır; biri hata verse de diğeri gösterilir.
    final postsFuture = AsyncValue.guard(() => postRepo.searchPosts(
          query,
          branch: state.branchFilter,
          type: state.typeFilter,
        ));
    final usersFuture = AsyncValue.guard(() => userRepo.searchUsers(query));
    final posts = await postsFuture;
    final users = await usersFuture;

    if (requestId != _requestId) return;
    state = state.copyWith(
      postResults: posts.whenData(_pager.first),
      userResults: users,
    );
  }

  void setBranchFilter(DentalBranch? branch) {
    state = state.copyWith(branchFilter: () => branch);
    if (state.query.isNotEmpty) search(state.query);
  }

  void setTypeFilter(PostType? type) {
    state = state.copyWith(typeFilter: () => type);
    if (state.query.isNotEmpty) search(state.query);
  }

  void clearFilters() {
    state = SearchState(query: state.query);
    if (state.query.isNotEmpty) search(state.query);
  }

  void clear() {
    _requestId++;
    _pager.reset();
    state = const SearchState();
  }

  Future<void> toggleLike(String postId) => _toggle(postId, PostToggle.like);

  Future<void> toggleBookmark(String postId) =>
      _toggle(postId, PostToggle.bookmark);

  /// Aynı sorgu ve filtrelerle sonraki sonuç sayfasını ekler.
  Future<void> loadMore() {
    final query = state.query;
    final branch = state.branchFilter;
    final type = state.typeFilter;
    return _pager.loadMore(
      (before) => ref.read(searchRepositoryProvider).searchPosts(
            query,
            branch: branch,
            type: type,
            before: before,
          ),
      (items) => state = state.copyWith(
        postResults: AsyncData([...?state.postResults.valueOrNull, ...items]),
      ),
    );
  }

  /// Sonuçlardaki tek postu günceller (detay ekranından senkronizasyon dahil).
  void patchPost(String postId, PostModel Function(PostModel) update) {
    final posts = state.postResults.valueOrNull;
    if (posts == null) return;
    state = state.copyWith(postResults: AsyncData([
      for (final p in posts) p.id == postId ? update(p) : p,
    ]));
  }

  void removePost(String postId) {
    final posts = state.postResults.valueOrNull;
    if (posts == null) return;
    state = state.copyWith(postResults: AsyncData([
      for (final p in posts) if (p.id != postId) p,
    ]));
  }

  /// Başka cihazda silinmiş post (NotFound) sonuçlardan düşer; hata yine
  /// fırlatılır ki UI kullanıcıya bildirsin.
  Future<void> _toggle(String postId, PostToggle toggle) async {
    try {
      await runPostToggle(
        ref,
        _pending,
        toggle,
        postId,
        current: () => state.postResults.valueOrNull
            ?.where((p) => p.id == postId)
            .firstOrNull,
        patch: (update) => patchPost(postId, update),
      );
    } on NotFoundFailure {
      removePost(postId);
      rethrow;
    }
  }
}

final searchProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchState>(
      () => SearchNotifier(),
    );
