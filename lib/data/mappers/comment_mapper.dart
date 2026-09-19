import '../../domain/entities/comment_entity.dart';
import 'user_mapper.dart';

class CommentMapper {
  /// Supabase tablosundan gelen satırı CommentEntity'e dönüştürür.
  static CommentEntity fromRow(Map<String, dynamic> row) {
    // Yazar alanı RLS veya silinme sebebiyle null dönebilir, güvenli okuma.
    final authorJson = row['author'] as Map<String, dynamic>?;
    final author = authorJson != null ? UserMapper.toSummary(authorJson) : null;

    // 'my_likes' alias'ı ile çektiğimiz alan (eq my_likes.user_id, uid)
    // Eğer liste boş değilse, sorguyu yapan kullanıcı bu yorumu beğenmiştir.
    final rawLikes = row['my_likes'] as List<dynamic>? ?? [];
    final isLiked = rawLikes.isNotEmpty;

    return CommentEntity(
      id: row['id'] as String,
      postId: row['post_id'] as String,
      userId: row['user_id'] as String,
      content: row['content'] as String,
      isBestAnswer: row['is_best_answer'] as bool? ?? false,
      likeCount: row['like_count'] as int? ?? 0,
      isLiked: isLiked,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
      author: author,
    );
  }
}
