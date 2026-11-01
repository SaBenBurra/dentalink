import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/enums.dart';
import '../core/error/app_failures.dart';
import '../core/utils/paging.dart';
import '../data/models/post_model.dart';
import '../data/models/tag_model.dart';
import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';
import 'post_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Arama satırı
// ─────────────────────────────────────────────────────────────────────────────

/// Arama satırı: `#` ile başlayan sözcükler etiket, kalanı metin.
({String text, List<String> tags}) parseExploreQuery(String raw) {
  final text = <String>[];
  final tags = <String>[];
  for (final word in raw.split(RegExp(r'\s+'))) {
    if (word.startsWith('#')) {
      final tag = word.replaceAll('#', '');
      if (tag.isNotEmpty) tags.add(tag);
    } else if (word.isNotEmpty) {
      text.add(word);
    }
  }
  return (text: text.join(' '), tags: tags);
}

/// Etiketi arama satırına yazılacak tek sözcüğe çevirir. Boşluk `_` olur;
/// sunucu ikisini de aynı etikete eşler (`tag_match_key`).
String hashtag(String name) =>
    '#${name.trim().replaceAll(RegExp(r'\s+'), '_')}';

/// Yazılmakta olan etiket (son sözcük `#` ile başlıyorsa, `#` olmadan); yoksa null.
String? typingTag(String raw) {
  if (raw.isEmpty || raw.endsWith(' ')) return null;
  final last = raw.split(' ').last;
  return last.startsWith('#') ? last.substring(1) : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Search State
// ─────────────────────────────────────────────────────────────────────────────

class SearchState {
  /// Arama satırı, ham hali (`#etiket` dahil).
  final String query;
  final DentalBranch? branch;
  final AsyncValue<List<PostModel>> posts;

  /// Yalnızca sorguda metin varken dolar.
  final AsyncValue<List<UserModel>> users;
  final bool hasMore;

  /// Sorgu yalnızca bu etiketse (popüler etiket seçili görünür).
  bool isOnlyTag(String name) => query.trim() == hashtag(name);

  const SearchState({
    this.query = '',
    this.branch,
    this.posts = const AsyncLoading(),
    this.users = const AsyncData([]),
    this.hasMore = false,
  });

  SearchState copyWith({
    String? query,
    // ValueGetter: branşı null'a (Tümü) çekebilmek için; '??' ile mümkün değil.
    DentalBranch? Function()? branch,
    AsyncValue<List<PostModel>>? posts,
    AsyncValue<List<UserModel>>? users,
    bool? hasMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      branch: branch != null ? branch() : this.branch,
      posts: posts ?? this.posts,
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Keşfet: arama satırı + branşa göre popüler postlar (offset sayfalı).
class SearchNotifier extends AutoDisposeNotifier<SearchState> {
  /// Yalnızca en son isteğin sonucu yazılır; yavaş eski bir yanıt yenisini ezmez.
  int _requestId = 0;
  final _pending = PostToggleQueue();

  /// Skorun hesaplandığı an; sayfalar arasında sabit (035).
  DateTime _now = DateTime.now();
  int _offset = 0;
  Future<void>? _loadingMore;

  @override
  SearchState build() {
    Future.microtask(_reload);
    return const SearchState();
  }

  void search(String query) {
    if (query == state.query) return;
    state = state.copyWith(query: query);
    _reload();
  }

  void setBranch(DentalBranch? branch) {
    if (branch == state.branch) return;
    state = state.copyWith(branch: () => branch);
    _reload();
  }

  /// Popüler etikete dokunuş: sorgu yalnızca etiket olur, branş Tümü'ye döner.
  void selectTag(String name) {
    state = state.copyWith(query: hashtag(name), branch: () => null);
    _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    final requestId = ++_requestId;
    _now = DateTime.now();
    _offset = 0;
    _loadingMore = null;
    final parsed = parseExploreQuery(state.query);
    final branch = state.branch;
    state = state.copyWith(
      posts: const AsyncLoading(),
      users: parsed.text.isEmpty ? const AsyncData([]) : const AsyncLoading(),
      hasMore: false,
    );

    // Post ve kullanıcı paralel; biri hata verse de diğeri gösterilir.
    final postsFuture = AsyncValue.guard(() => _fetch(parsed, branch, 0));
    final usersFuture = parsed.text.isEmpty
        ? Future.value(const AsyncData(<UserModel>[]))
        : AsyncValue.guard(
            () => ref.read(userRepositoryProvider).searchUsers(parsed.text),
          );
    final posts = await postsFuture;
    final users = await usersFuture;

    if (requestId != _requestId) return;
    _offset = pageSize;
    state = state.copyWith(
      posts: posts,
      users: users,
      hasMore: (posts.valueOrNull?.length ?? 0) >= pageSize,
    );
  }

  Future<List<PostModel>> _fetch(
    ({String text, List<String> tags}) parsed,
    DentalBranch? branch,
    int offset,
  ) => ref
      .read(searchRepositoryProvider)
      .popularPosts(
        query: parsed.text,
        tags: parsed.tags,
        branch: branch,
        now: _now,
        offset: offset,
      );

  /// Sonraki sayfa; aynı anda gelen çağrılar aynı isteği bekler. Hata fırlatılır.
  Future<void> loadMore() {
    if (!state.hasMore) return Future.value();
    return _loadingMore ??= _loadMore();
  }

  Future<void> _loadMore() async {
    final requestId = _requestId;
    try {
      final items = await _fetch(
        parseExploreQuery(state.query),
        state.branch,
        _offset,
      );
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

  Future<void> toggleLike(String postId) => _toggle(postId, PostToggle.like);

  Future<void> toggleBookmark(String postId) =>
      _toggle(postId, PostToggle.bookmark);

  /// Sonuçlardaki tek postu günceller (detay ekranından senkronizasyon dahil).
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

  /// Engellenen kullanıcının postları ve kendisi sonuçlardan düşer.
  void removeAuthor(String userId) {
    final posts = state.posts.valueOrNull;
    final users = state.users.valueOrNull;
    state = state.copyWith(
      posts: posts == null
          ? null
          : AsyncData([
              for (final p in posts)
                if (p.userId != userId) p,
            ]),
      users: users == null
          ? null
          : AsyncData([
              for (final u in users)
                if (u.id != userId) u,
            ]),
    );
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

final searchProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchState>(
      () => SearchNotifier(),
    );

/// Keşfet'teki "Popüler konular"; yenilemede invalidate edilir.
final popularTagsProvider = FutureProvider.autoDispose<List<TagModel>>(
  (ref) => ref.watch(searchRepositoryProvider).popularTags(),
);
