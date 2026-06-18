import '../datasources/mock_datasource.dart';
import '../models/comment_model.dart';
import 'comment_repository.dart';


/// Sahte yorum repository. Faz 3'te SupabaseCommentRepository ile swap edilir.
class MockCommentRepository implements CommentRepository {
  static const _delay = Duration(milliseconds: 350);

  // Post başına in-memory yorum listesi.
  final Map<String, List<CommentModel>> _commentOverrides = {};

  List<CommentModel> _commentsFor(String postId) {
    return _commentOverrides[postId] ??
        (MockDatasource.comments[postId] ?? []);
  }

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    await Future.delayed(_delay);
    final list = List<CommentModel>.from(_commentsFor(postId));
    // En iyi cevap en üste gelir.
    list.sort((a, b) {
      if (a.isBestAnswer && !b.isBestAnswer) return -1;
      if (!a.isBestAnswer && b.isBestAnswer) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<CommentModel> addComment(String postId, String content) async {
    await Future.delayed(_delay);
    final currentUser = MockDatasource.userById(MockDatasource.currentUserId);
    final newComment = CommentModel(
      id: 'c_new_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: currentUser.id,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: currentUser,
    );
    final existing = List<CommentModel>.from(_commentsFor(postId));
    existing.add(newComment);
    _commentOverrides[postId] = existing;
    return newComment;
  }

  @override
  Future<CommentModel> markBestAnswer(String commentId) async {
    await Future.delayed(_delay);
    // Tüm postlarda bu comment'i bul ve güncelle.
    for (final entry in {
      ...MockDatasource.comments,
      ..._commentOverrides,
    }.entries) {
      final list = List<CommentModel>.from(entry.value);
      final idx = list.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        // Önce tüm best_answer'ları kaldır.
        final updated = list
            .map((c) => c.copyWith(isBestAnswer: c.id == commentId))
            .toList();
        _commentOverrides[entry.key] = updated;
        return updated[idx].copyWith(isBestAnswer: true);
      }
    }
    throw Exception('Comment not found: $commentId');
  }

  @override
  Future<CommentModel> likeComment(String commentId) async {
    await Future.delayed(_delay);
    return _updateComment(commentId, (c) => c.copyWith(
      isLiked: true,
      likeCount: c.likeCount + 1,
    ));
  }

  @override
  Future<CommentModel> unlikeComment(String commentId) async {
    await Future.delayed(_delay);
    return _updateComment(commentId, (c) => c.copyWith(
      isLiked: false,
      likeCount: (c.likeCount - 1).clamp(0, 9999),
    ));
  }

  CommentModel _updateComment(
    String commentId,
    CommentModel Function(CommentModel) transform,
  ) {
    final allSources = <String, List<CommentModel>>{
      ...MockDatasource.comments,
      ..._commentOverrides,
    };
    for (final entry in allSources.entries) {
      final list = List<CommentModel>.from(entry.value);
      final idx = list.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        final updated = transform(list[idx]);
        list[idx] = updated;
        _commentOverrides[entry.key] = list;
        return updated;
      }
    }
    throw Exception('Comment not found: $commentId');
  }
}
