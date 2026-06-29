import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/enums.dart';
import '../data/models/post_model.dart';
import '../data/models/user_model.dart';
import 'feed_provider.dart';
import 'user_provider.dart';

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
    DentalBranch? branchFilter,
    PostType? typeFilter,
    AsyncValue<List<PostModel>>? postResults,
    AsyncValue<List<UserModel>>? userResults,
  }) {
    return SearchState(
      query: query ?? this.query,
      branchFilter: branchFilter ?? this.branchFilter,
      typeFilter: typeFilter ?? this.typeFilter,
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
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(
      query: query,
      postResults: const AsyncLoading(),
      userResults: const AsyncLoading(),
    );

    final postRepo = ref.read(postRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    // Post ve kullanıcı aramasını paralel çalıştır.
    final results = await Future.wait([
      postRepo.searchPosts(
        query,
        branch: state.branchFilter,
        type: state.typeFilter,
      ),
      userRepo.searchUsers(query),
    ]);

    state = state.copyWith(
      postResults: AsyncData(results[0] as List<PostModel>),
      userResults: AsyncData(results[1] as List<UserModel>),
    );
  }

  void setBranchFilter(DentalBranch? branch) {
    state = state.copyWith(branchFilter: branch);
    if (state.query.isNotEmpty) search(state.query);
  }

  void setTypeFilter(PostType? type) {
    state = state.copyWith(typeFilter: type);
    if (state.query.isNotEmpty) search(state.query);
  }

  void clearFilters() {
    state = SearchState(query: state.query);
    if (state.query.isNotEmpty) search(state.query);
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchState>(
      () => SearchNotifier(),
    );
