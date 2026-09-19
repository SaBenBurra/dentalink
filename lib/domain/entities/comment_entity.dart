import 'package:equatable/equatable.dart';
import 'user_summary.dart';

/// Yorum Entity'si (Domain Katmanı)
/// JSON veya Supabase spesifik hiçbir mantık içermez.
class CommentEntity extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String content;
  
  /// Soru gönderilerinde: bu yorum en iyi cevap mı?
  final bool isBestAnswer;
  
  final int likeCount;
  final bool isLiked;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// Embed: yorumu yazan kullanıcı.
  /// RLS kuralları sebebiyle yazar çekilemezse veya silinmişse null olabilir.
  final UserSummary? author;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.isBestAnswer = false,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
    this.author,
  });

  CommentEntity copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    bool? isBestAnswer,
    int? likeCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserSummary? author,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
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
        isBestAnswer,
        likeCount,
        isLiked,
        createdAt,
        updatedAt,
        author,
      ];
}
