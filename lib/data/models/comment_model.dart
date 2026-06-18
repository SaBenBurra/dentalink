import 'user_model.dart';

/// Yorum modeli — Supabase `comments` tablosuyla eşleşir.
class CommentModel {
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
  final UserModel author;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.isBestAnswer = false,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
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
      isBestAnswer: isBestAnswer ?? this.isBestAnswer,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CommentModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
