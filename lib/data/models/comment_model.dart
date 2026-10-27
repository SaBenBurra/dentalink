import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Yorum modeli.
class CommentModel extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String content;

  /// Yanıtlanan yorum; null = üst seviye yorum/cevap.
  final String? parentId;

  /// Doğrudan yanıt sayısı (DB trigger'ı tutar).
  final int replyCount;
  
  /// Soru gönderilerinde: bu yorum en iyi cevap mı?
  final bool isBestAnswer;
  
  final int likeCount;
  final bool isLiked;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// Embed: yorumu yazan kullanıcı.
  /// RLS kuralları sebebiyle yazar çekilemezse veya silinmişse null olabilir.
  final UserModel? author;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.parentId,
    this.replyCount = 0,
    this.isBestAnswer = false,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
    this.author,
  });

  /// Supabase satırından (yazar ve `my_likes` gömülü) yorum üretir.
  factory CommentModel.fromRow(Map<String, dynamic> row) {
    // Yazar RLS veya silinme sebebiyle null dönebilir.
    final authorJson = row['author'] as Map<String, dynamic>?;
    return CommentModel(
      id: row['id'] as String,
      postId: row['post_id'] as String,
      userId: row['user_id'] as String,
      content: row['content'] as String,
      parentId: row['parent_id'] as String?,
      replyCount: row['reply_count'] as int? ?? 0,
      isBestAnswer: row['is_best_answer'] as bool? ?? false,
      likeCount: row['like_count'] as int? ?? 0,
      // `my_likes` yalnızca oturumdaki kullanıcının beğenisini içerir.
      isLiked: (row['my_likes'] as List<dynamic>? ?? const []).isNotEmpty,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
      author: authorJson == null ? null : UserModel.fromJson(authorJson),
    );
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    int? replyCount,
    bool? isBestAnswer,
    int? likeCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? author,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      parentId: parentId,
      replyCount: replyCount ?? this.replyCount,
      isBestAnswer: isBestAnswer ?? this.isBestAnswer,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        userId,
        content,
        parentId,
        replyCount,
        isBestAnswer,
        likeCount,
        isLiked,
        createdAt,
        updatedAt,
        author,
      ];
}
