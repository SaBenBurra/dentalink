import '../datasources/mock_datasource.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';

/// Sahte yorum repository. Faz 3'te SupabaseCommentRepository ile swap edilir.
class MockCommentRepository implements CommentRepository {
  final Duration _delay = const Duration(milliseconds: 600);

  // Post başına in-memory yorum listesi.
  final Map<String, List<CommentEntity>> _commentOverrides = {};

  List<CommentEntity> _commentsFor(String postId) {
    return _commentOverrides[postId] ?? (MockDatasource.comments[postId] ?? []);
  }

  @override
  Future<List<CommentEntity>> getComments(String postId, {int limit = 50, int offset = 0}) async {
    await Future.delayed(_delay);
    final list = List<CommentEntity>.from(_commentsFor(postId));
    // En iyi cevap en üste gelir.
    list.sort((a, b) {
      if (a.isBestAnswer && !b.isBestAnswer) return -1;
      if (!a.isBestAnswer && b.isBestAnswer) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    
    // Basit in-memory sayfalama
    if (offset >= list.length) return [];
    return list.skip(offset).take(limit).toList();
  }

  @override
  Future<CommentEntity> addComment(String postId, String content) async {
    await Future.delayed(_delay);
    final userModel = MockDatasource.userSummaryById(MockDatasource.currentUserId);
    final newComment = CommentEntity(
      id: 'c_new_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: userModel.id,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: userModel,
    );
    final existing = List<CommentEntity>.from(_commentsFor(postId));
    existing.add(newComment);
    _commentOverrides[postId] = existing;
    return newComment;
  }

  @override
  Future<void> markBestAnswer(String commentId) async {
    await Future.delayed(_delay);
    for (final entry in {
      ...MockDatasource.comments,
      ..._commentOverrides,
    }.entries) {
      final list = List<CommentEntity>.from(entry.value);
      final idx = list.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        // Önce tüm best_answer'ları kaldır.
        final updated = list
            .map((c) => c.copyWith(isBestAnswer: c.id == commentId))
            .toList();
        _commentOverrides[entry.key] = updated;
        return;
      }
    }
    throw Exception('Comment not found: $commentId');
  }

  @override
  Future<void> likeComment(String commentId) async {
    await Future.delayed(_delay);
    _updateComment(
      commentId,
      (c) => c.copyWith(isLiked: true, likeCount: c.likeCount + 1),
    );
  }

  @override
  Future<void> unlikeComment(String commentId) async {
    await Future.delayed(_delay);
    _updateComment(
      commentId,
      (c) => c.copyWith(
        isLiked: false,
        likeCount: (c.likeCount - 1).clamp(0, 9999),
      ),
    );
  }

  void _updateComment(
    String commentId,
    CommentEntity Function(CommentEntity) transform,
  ) {
    final allSources = <String, List<CommentEntity>>{
      ...MockDatasource.comments,
      ..._commentOverrides,
    };
    for (final entry in allSources.entries) {
      final list = List<CommentEntity>.from(entry.value);
      final idx = list.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        final updated = transform(list[idx]);
        list[idx] = updated;
        _commentOverrides[entry.key] = list;
        return;
      }
    }
    throw Exception('Comment not found: $commentId');
  }
}
