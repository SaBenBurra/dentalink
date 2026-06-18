import 'enums.dart';
import 'tag_model.dart';
import 'user_model.dart';

/// Gönderi modeli — Supabase `posts` + `post_images` + `post_tags` tablosuyla eşleşir.
class PostModel {
  final String id;
  final String userId;
  final PostType type;
  final String title;
  final String content;

  /// Sadece vaka gönderilerinde zorunlu.
  final DentalBranch? branch;

  /// post_images tablosundan çekilen URL listesi (order_index sırasına göre).
  final List<String> imageUrls;

  final List<TagModel> tags;

  // Denormalize sayaçlar (trigger ile güncellenen DB sütunlarından gelir)
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final int viewCount;

  // UI state — mevcut kullanıcı için
  final bool isLiked;
  final bool isBookmarked;

  /// Soru gönderilerinde: en iyi cevap seçildi mi?
  final bool isSolved;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Embed: gönderiyi oluşturan kullanıcı.
  /// Feed listelerinde ayrı JOIN sorgusu yapmayı engeller.
  final UserModel author;

  const PostModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.branch,
    this.imageUrls = const [],
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.bookmarkCount = 0,
    this.viewCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isSolved = false,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  PostModel copyWith({
    String? id,
    String? userId,
    PostType? type,
    String? title,
    String? content,
    DentalBranch? branch,
    List<String>? imageUrls,
    List<TagModel>? tags,
    int? likeCount,
    int? commentCount,
    int? bookmarkCount,
    int? viewCount,
    bool? isLiked,
    bool? isBookmarked,
    bool? isSolved,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? author,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      branch: branch ?? this.branch,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      viewCount: viewCount ?? this.viewCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isSolved: isSolved ?? this.isSolved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PostModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
