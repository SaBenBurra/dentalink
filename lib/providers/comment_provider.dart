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

/// Bir yorumun yanıt listesinin anahtarı.
typedef ReplyThread = ({String postId, String parentId});

/// Sayfalı bir yorum listesi: postun üst seviye yorumları ([CommentsNotifier])
/// ya da bir yorumun yanıtları ([RepliesNotifier]). Beğeni, yanıt ekleme ve
/// engelleme her iki listede aynı çalışır.
abstract class CommentThreadNotifier<A>
    extends AutoDisposeFamilyAsyncNotifier<List<CommentModel>, A> {
  final _pendingLikes = <String>{};
  final _pager = Pager<CommentModel>();

  CommentRepository get _repo => ref.read(commentRepositoryProvider);

  String get postId;

  Future<PageResult<CommentModel>> _fetch(CommentRepository repo, PageCursor? after);

  bool get hasMore => _pager.hasMore;

  @override
  Future<List<CommentModel>> build(A arg) async {
    return _pager.first(await _fetch(ref.watch(commentRepositoryProvider), null));
  }

  /// Sonraki sayfayı ekler. Bu ekranda eklenen yorum kendi sayfası gelince
  /// listeden çıkıp sayfadaki yerine geçer (çift görünmez).
  Future<void> loadMore() => _pager.loadMore(
        (after) => _fetch(_repo, after),
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

  String _validated(String content) {
    final text = content.trim();
    if (text.isEmpty) throw const ValidationFailure('empty_content');
    return text;
  }

  void _append(CommentModel comment) {
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf(); // liste yüklenmemişken tek yorumluk listeyle ezme
      return;
    }
    state = AsyncData([...current, comment]);
  }

  /// Bu listedeki [parent]'a yanıt yazar: ebeveynin sayacı +1, yanıt listesi
  /// açıksa sonuna eklenir (kapalıysa açılınca sunucudan gelir).
  Future<void> addReply(CommentModel parent, String content) => _keepingAlive(() async {
    final reply = await _repo.addComment(postId, _validated(content), parentId: parent.id);
    _bumpCommentCount();
    final cur = _find(parent.id);
    if (cur != null) _replace(cur.copyWith(replyCount: cur.replyCount + 1));
    final replies = repliesProvider((postId: postId, parentId: parent.id));
    if (ref.exists(replies)) ref.read(replies.notifier)._append(reply);
  });

  /// Sayaç DB trigger'ıyla artar (yanıtlar dahil); ekrandaki kopyalar yeniden
  /// çekilmeden +1 olur.
  void _bumpCommentCount() {
    PostModel bump(PostModel p) => p.copyWith(commentCount: p.commentCount + 1);
    if (ref.exists(postDetailProvider(postId))) {
      ref.read(postDetailProvider(postId).notifier).patch(bump);
    }
    if (ref.exists(feedProvider)) ref.read(feedProvider.notifier).patchPost(postId, bump);
    if (ref.exists(searchProvider)) ref.read(searchProvider.notifier).patchPost(postId, bump);
  }

  /// Engellenen kullanıcının yorumları listeden düşer (sayaç DB'de değişmez).
  void removeAuthor(String userId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([for (final c in current) if (c.userId != userId) c]);
  }

  CommentModel? _find(String id) =>
      state.valueOrNull?.where((c) => c.id == id).firstOrNull;

  /// Her zaman GÜNCEL state üzerinden id ile değiştirir (eski liste kopyası yok).
  void _replace(CommentModel updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([for (final c in current) c.id == updated.id ? updated : c]);
  }

  Future<void> toggleLike(String commentId) => _keepingAlive(() async {
    if (!_pendingLikes.add(commentId)) return; // Çift tıklama koruması

    try {
      final original = _find(commentId);
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
        final cur = _find(commentId);
        if (cur != null) {
          _replace(cur.copyWith(isLiked: original.isLiked, likeCount: original.likeCount));
        }
        rethrow;
      }
    } finally {
      _pendingLikes.remove(commentId);
    }
  });
}

/// Postun üst seviye yorumları / cevapları.
class CommentsNotifier extends CommentThreadNotifier<String> {
  @override
  String get postId => arg;

  @override
  Future<PageResult<CommentModel>> _fetch(CommentRepository repo, PageCursor? after) =>
      repo.getComments(arg, after: after);

  Future<void> addComment(String content) => _keepingAlive(() async {
    final newComment = await _repo.addComment(arg, _validated(content));
    _bumpCommentCount();
    _append(newComment);
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

/// Bir yorumun doğrudan yanıtları.
class RepliesNotifier extends CommentThreadNotifier<ReplyThread> {
  @override
  String get postId => arg.postId;

  @override
  Future<PageResult<CommentModel>> _fetch(CommentRepository repo, PageCursor? after) =>
      repo.getReplies(arg.parentId, after: after);
}

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsNotifier, List<CommentModel>, String>(() {
      return CommentsNotifier();
    });

final repliesProvider = AsyncNotifierProvider.autoDispose
    .family<RepliesNotifier, List<CommentModel>, ReplyThread>(RepliesNotifier.new);

/// [comment]'in bulunduğu liste: üst seviye ya da ebeveyninin yanıtları.
CommentThreadNotifier<Object> commentThreadOf(WidgetRef ref, CommentModel comment) {
  final parentId = comment.parentId;
  return parentId == null
      ? ref.read(commentsProvider(comment.postId).notifier)
      : ref.read(repliesProvider((postId: comment.postId, parentId: parentId)).notifier);
}
