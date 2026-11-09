import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_failures.dart';
import '../core/utils/paging.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';
import 'bookmark_provider.dart';
import 'feed_provider.dart';
import 'post_toggle.dart';
import 'search_provider.dart';
import 'treatment_archive_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tek Post Detay Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Listeden açılan postun elde olan kopyası (post id → post). Post sayfası
/// bunu bırakır, [PostDetailNotifier] ilk karede alıp yükleniyor ekranı
/// göstermeden çizer; sunucudaki güncel hâl arkadan gelir.
final postSeedsProvider = Provider<Map<String, PostModel>>((ref) => {});

/// Aynı postun ekrandaki kopyalarını (feed, arama, kaydedilenler, yazarın
/// profili, açık tedavi arşivleri) yeniden çekmeden günceller.
void patchPostCopies(
  Ref ref,
  String postId,
  String? authorId,
  PostModel Function(PostModel) update,
) {
  if (ref.exists(feedProvider)) {
    ref.read(feedProvider.notifier).patchPost(postId, update);
  }
  if (ref.exists(listingFeedProvider)) {
    ref.read(listingFeedProvider.notifier).patchPost(postId, update);
  }
  if (ref.exists(searchProvider)) {
    ref.read(searchProvider.notifier).patchPost(postId, update);
  }
  if (ref.exists(bookmarkProvider)) {
    ref.read(bookmarkProvider.notifier).patchPost(postId, update);
  }
  if (authorId != null && ref.exists(userPostsProvider(authorId))) {
    ref.read(userPostsProvider(authorId).notifier).patchPost(postId, update);
  }
  for (final slug in ref.read(openArchivesProvider)) {
    ref.read(treatmentArchiveProvider(slug).notifier).patchPost(postId, update);
  }
}

void _removePostCopies(Ref ref, String postId, String? authorId) {
  if (ref.exists(feedProvider)) {
    ref.read(feedProvider.notifier).removePost(postId);
  }
  if (ref.exists(listingFeedProvider)) {
    ref.read(listingFeedProvider.notifier).removePost(postId);
  }
  if (ref.exists(searchProvider)) {
    ref.read(searchProvider.notifier).removePost(postId);
  }
  if (ref.exists(bookmarkProvider)) {
    ref.read(bookmarkProvider.notifier).removePost(postId);
  }
  if (authorId != null && ref.exists(userPostsProvider(authorId))) {
    ref.read(userPostsProvider(authorId).notifier).removePost(postId);
  }
  for (final slug in ref.read(openArchivesProvider)) {
    ref.read(treatmentArchiveProvider(slug).notifier).removePost(postId);
  }
}

class PostDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<PostModel, String> {
  bool _disposed = false;

  @override
  FutureOr<PostModel> build(String arg) {
    ref.onDispose(() => _disposed = true);
    final seed = ref.read(postSeedsProvider).remove(arg);
    if (seed == null) return ref.read(feedRepositoryProvider).getPostById(arg);
    _revalidate(seed);
    return seed;
  }

  /// Listeden gelen kopyayı sunucudakiyle değiştirir. Bu arada yapılan
  /// beğeni/kaydetmenin iyimser değeri korunur.
  Future<void> _revalidate(PostModel seed) async {
    final PostModel fresh;
    try {
      fresh = await ref.read(feedRepositoryProvider).getPostById(arg);
    } on NotFoundFailure catch (e, st) {
      if (_disposed) return;
      state = AsyncError(e, st);
      _removePostCopies(ref, arg, seed.userId);
      return;
    } catch (_) {
      // Elde geçerli bir kopya var; ağ hatasında o gösterilmeye devam eder,
      // yorumların kendi hata/yeniden dene durumu var.
      return;
    }
    if (_disposed) return;
    final current = state.valueOrNull;
    state = AsyncData(
      current == null || identical(current, seed)
          ? fresh
          : PostToggle.bookmark.copyFields(
              PostToggle.like.copyFields(fresh, current),
              current,
            ),
    );
  }

  final _pending = PostToggleQueue();

  void patch(PostModel Function(PostModel) update) {
    final post = state.valueOrNull;
    if (post != null) state = AsyncData(update(post));
  }

  /// Post silindi: açık sayfa "bulunamadı" durumuna geçer (PostScreen kendini kapatır).
  void markDeleted() =>
      state = AsyncError(const NotFoundFailure(), StackTrace.current);

  /// İlanı satıldı ya da yeniden satışta yapar. Satılan ilan Ticaret
  /// listesinden düşer; geri alınan, liste yeniden çekilince görünür.
  Future<void> setSold(bool sold) async {
    final updated = await ref
        .read(listingRepositoryProvider)
        .setListingSold(arg, sold: sold);
    if (_disposed) return;
    state = AsyncData(updated);
    patchPostCopies(ref, arg, updated.userId, (_) => updated);
    if (sold) {
      if (ref.exists(listingFeedProvider)) {
        ref.read(listingFeedProvider.notifier).removePost(arg);
      }
    } else {
      ref.invalidate(listingFeedProvider);
    }
  }

  Future<void> toggleLike() => _toggle(PostToggle.like);

  Future<void> toggleBookmark() => _toggle(PostToggle.bookmark);

  /// Post başka cihazda silinmişse ekran "bulunamadı" durumuna geçer;
  /// diğer hatalar UI'ın göstermesi için fırlatılır. Listelerdeki aynı post
  /// yeniden çekilmeden güncellenir.
  Future<void> _toggle(PostToggle toggle) async {
    final authorId = state.valueOrNull?.userId;
    try {
      final server = await runPostToggle(
        ref,
        _pending,
        toggle,
        arg,
        current: () => state.valueOrNull,
        patch: patch,
      );
      if (server == null) return;
      patchPostCopies(ref, arg, authorId, (p) => toggle.copyFields(p, server));
    } on NotFoundFailure catch (e, st) {
      state = AsyncError(e, st);
      _removePostCopies(ref, arg, authorId);
    }
  }
}

final postDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PostDetailNotifier, PostModel, String>(() {
      return PostDetailNotifier();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Kullanıcı Postları Provider
// ─────────────────────────────────────────────────────────────────────────────

class UserPostsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<PostModel>, String> {
  final _pager = Pager<PostModel>();

  bool get hasMore => _pager.hasMore;

  @override
  Future<List<PostModel>> build(String arg) async =>
      _pager.first(await ref.read(feedRepositoryProvider).getPostsByUser(arg));

  Future<void> loadMore() => _pager.loadMore(
    (before) =>
        ref.read(feedRepositoryProvider).getPostsByUser(arg, before: before),
    (items) {
      final posts = state.valueOrNull;
      if (posts != null) state = AsyncData([...posts, ...items]);
    },
  );

  /// Listedeki tek postu yeniden çekmeden günceller (yüklenen sayfalar kalır).
  void patchPost(String postId, PostModel Function(PostModel) update) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData([for (final p in posts) p.id == postId ? update(p) : p]);
  }

  void removePost(String postId) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData([
      for (final p in posts)
        if (p.id != postId) p,
    ]);
  }
}

final userPostsProvider = AsyncNotifierProvider.autoDispose
    .family<UserPostsNotifier, List<PostModel>, String>(UserPostsNotifier.new);
