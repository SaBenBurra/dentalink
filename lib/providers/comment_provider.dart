import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/comment_model.dart';
import '../data/repositories/comment_repository.dart';
import '../data/providers/repository_providers.dart';
import '../core/error/app_failures.dart';
import '../core/utils/paging.dart';
import '../data/models/post_model.dart';
import 'feed_provider.dart';
import 'post_provider.dart';
import 'search_provider.dart';

class CommentsNotifier extends AutoDisposeFamilyAsyncNotifier<List<CommentModel>, String> {
  final _pendingLikes = <String>{};
  final _pager = Pager<CommentModel>();

  CommentRepository get _repo => ref.read(commentRepositoryProvider);

  bool get hasMore => _pager.hasMore;

  @override
  Future<List<CommentModel>> build(String postId) async {
    return _pager.first(await ref.watch(commentRepositoryProvider).getComments(postId));
  }

  /// Sonraki yorum sayfasını ekler. Bu ekranda eklenen yorum kendi sayfası
  /// gelince listeden çıkıp sayfadaki yerine geçer (çift görünmez).
  Future<void> loadMore() => _pager.loadMore(
        (after) => _repo.getComments(arg, after: after),
        (items) {
          final current = state.valueOrNull;
          if (current == null) return;
          final ids = {for (final c in items) c.id};
          state = AsyncData([
            for (final c in current) if (!ids.contains(c.id)) c,
            ...items,
          ]);
        },
      );

  Future<T> _keepingAlive<T>(Future<T> Function() action) async {
    final link = ref.keepAlive();
    try {
      return await action();
    } finally {
      link.close(); // autoDispose tekrar devreye girer
    }
  }

  Future<void> addComment(String content) => _keepingAlive(() async {
    final text = content.trim();
    if (text.isEmpty) throw const ValidationFailure('empty_content');
    final newComment = await _repo.addComment(arg, text);
    _bumpCommentCount();
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf(); // liste yüklenmemişken tek yorumluk listeyle ezme
      return;
    }
    state = AsyncData([...current, newComment]);
  });

  /// Sayaç DB trigger'ıyla artar; ekrandaki kopyalar yeniden çekilmeden +1 olur.
  void _bumpCommentCount() {
    PostModel bump(PostModel p) => p.copyWith(commentCount: p.commentCount + 1);
    if (ref.exists(postDetailProvider(arg))) {
      ref.read(postDetailProvider(arg).notifier).patch(bump);
    }
    if (ref.exists(feedProvider)) ref.read(feedProvider.notifier).patchPost(arg, bump);
    if (ref.exists(searchProvider)) ref.read(searchProvider.notifier).patchPost(arg, bump);
  }

  /// Engellenen kullanıcının yorumları listeden düşer (sayaç DB'de değişmez).
  void removeAuthor(String userId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([for (final c in current) if (c.userId != userId) c]);
  }

  /// Her zaman GÜNCEL state üzerinden id ile değiştirir (eski liste kopyası yok).
  void _replace(CommentModel updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([for (final c in current) c.id == updated.id ? updated : c]);
  }

  Future<void> toggleLike(String commentId) => _keepingAlive(() async {
    if (!_pendingLikes.add(commentId)) return; // Çift tıklama koruması

    try {
      final original = state.valueOrNull?.where((c) => c.id == commentId).firstOrNull;
      if (original == null) return;
      final wasLiked = original.isLiked;

      // Optimistic update
      _replace(original.copyWith(
        isLiked: !wasLiked,
        likeCount: original.likeCount + (wasLiked ? -1 : 1),
      ));

      try {
        if (wasLiked) {
          await _repo.unlikeComment(commentId);
        } else {
          await _repo.likeComment(commentId);
        }
      } catch (_) {
        // Rollback: Sadece değişen like alanlarını geri al, böylece markBestAnswer ile çakışmaz
        final cur = state.valueOrNull?.where((c) => c.id == commentId).firstOrNull;
        if (cur != null) {
          _replace(cur.copyWith(isLiked: original.isLiked, likeCount: original.likeCount));
        }
        rethrow;
      }
    } finally {
      _pendingLikes.remove(commentId);
    }
  });

  Future<void> markBestAnswer(String commentId) =>
      _setBestAnswer(() => _repo.markBestAnswer(commentId));

  Future<void> unmarkBestAnswer(String commentId) =>
      _setBestAnswer(() => _repo.unmarkBestAnswer(commentId));

  Future<void> _setBestAnswer(Future<void> Function() rpc) => _keepingAlive(() async {
    await rpc();

    // İşlem başarılı, sorunun "çözüldü" (is_solved) state'ini yenile
    ref.invalidate(postDetailProvider(arg));
    
    try {
      // Listeyi arka planda yenile, mevcut liste (AsyncData) ekranda kalmaya devam eder,
      // böylece loading spinner (AsyncLoading) ile ekran sıfırlanmaz.
      final firstPage = await _repo.getComments(arg);
      state = AsyncData(_pager.first(firstPage));
    } catch (_) {
      // İşlem başarılı; listeyi çekme başarısızsa eski liste ekranda kalsın, hata fırlatma.
    }
  });
}

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsNotifier, List<CommentModel>, String>(() {
      return CommentsNotifier();
    });
