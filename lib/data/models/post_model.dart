import 'enums.dart';
import 'tag_model.dart';
import 'user_model.dart';

/// Gönderi modeli (Base)
sealed class PostModel {
  final String id;
  final String userId;
  final PostType type;
  final String title;
  final String content;

  final List<TagModel> tags;

  // Denormalize sayaçlar
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final int viewCount;

  // UI state
  final bool isLiked;
  final bool isBookmarked;

  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel author;

  const PostModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.bookmarkCount = 0,
    this.viewCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
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
    List<TagModel>? tags,
    int? likeCount,
    int? commentCount,
    int? bookmarkCount,
    int? viewCount,
    bool? isLiked,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? author,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PostModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Vaka gönderisi
class CasePostModel extends PostModel {
  final DentalBranch? branch;
  final List<String> imageUrls;

  const CasePostModel({
    required super.id,
    required super.userId,
    super.type = PostType.casePost,
    required super.title,
    required super.content,
    this.branch,
    this.imageUrls = const [],
    super.tags,
    super.likeCount,
    super.commentCount,
    super.bookmarkCount,
    super.viewCount,
    super.isLiked,
    super.isBookmarked,
    required super.createdAt,
    required super.updatedAt,
    required super.author,
  });

  @override
  CasePostModel copyWith({
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
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? author,
  }) {
    return CasePostModel(
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
    );
  }
}

/// Soru gönderisi
class QuestionPostModel extends PostModel {
  final bool isSolved;

  const QuestionPostModel({
    required super.id,
    required super.userId,
    super.type = PostType.question,
    required super.title,
    required super.content,
    this.isSolved = false,
    super.tags,
    super.likeCount,
    super.commentCount,
    super.bookmarkCount,
    super.viewCount,
    super.isLiked,
    super.isBookmarked,
    required super.createdAt,
    required super.updatedAt,
    required super.author,
  });

  @override
  QuestionPostModel copyWith({
    String? id,
    String? userId,
    PostType? type,
    String? title,
    String? content,
    bool? isSolved,
    List<TagModel>? tags,
    int? likeCount,
    int? commentCount,
    int? bookmarkCount,
    int? viewCount,
    bool? isLiked,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? author,
  }) {
    return QuestionPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      isSolved: isSolved ?? this.isSolved,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      viewCount: viewCount ?? this.viewCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
    );
  }
}
