import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/comment_entity.dart';
import '../domain/repositories/comment_repository.dart';
import '../data/providers/repository_providers.dart';
import '../core/error/app_failures.dart';
import 'post_provider.dart';

class CommentsNotifier extends AutoDisposeFamilyAsyncNotifier<List<CommentEntity>, String> {
  final _pendingLikes = <String>{};

  CommentRepository get _repo => ref.read(commentRepositoryProvider);

  @override
  Future<List<CommentEntity>> build(String postId) {
    return ref.watch(commentRepositoryProvider).getComments(postId);
  }

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
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf(); // liste yüklenmemişken tek yorumluk listeyle ezme
      return;
    }
    state = AsyncData([...current, newComment]);
  });

  /// Her zaman GÜNCEL state üzerinden id ile değiştirir (eski liste kopyası yok).
  void _replace(CommentEntity updated) {
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

  Future<void> markBestAnswer(String commentId) => _keepingAlive(() async {
    await _repo.markBestAnswer(commentId);
    
    // İşlem başarılı, sorunun "çözüldü" (is_solved) state'ini yenile
    ref.invalidate(postDetailProvider(arg));
    
    try {
      // Listeyi arka planda yenile, mevcut liste (AsyncData) ekranda kalmaya devam eder,
      // böylece loading spinner (AsyncLoading) ile ekran sıfırlanmaz.
      final newList = await _repo.getComments(arg);
      state = AsyncData(newList);
    } catch (_) {
      // İşlem başarılı; listeyi çekme başarısızsa eski liste ekranda kalsın, hata fırlatma.
    }
  });
}

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsNotifier, List<CommentEntity>, String>(() {
      return CommentsNotifier();
    });
