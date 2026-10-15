import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/enums.dart';
import '../data/models/post_model.dart';
import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';

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

  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    final requestId = ++_requestId;
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
    state = state.copyWith(postResults: posts, userResults: users);
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
    state = const SearchState();
  }

  Future<void> toggleLike(String postId) async {
    final posts = state.postResults.valueOrNull;
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
    state = state.copyWith(postResults: AsyncData(newList));
  }

  Future<void> toggleBookmark(String postId) async {
    final posts = state.postResults.valueOrNull;
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
    state = state.copyWith(postResults: AsyncData(newList));
  }
}

final searchProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchState>(
      () => SearchNotifier(),
    );
