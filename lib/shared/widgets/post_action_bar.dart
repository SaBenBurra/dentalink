import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'like_button.dart';
import 'bookmark_button.dart';
import 'stat_count.dart';

/// Gönderi kartlarının alt kısmında yer alan etkileşim çubuğu.
///
/// Beğeni, yorum ve kaydetme aksiyonlarını yatay bir satırda gösterir.
/// [compact] modu daha küçük ikonlar ve dar boşluklar kullanır.
///
/// Örnek kullanım:
/// ```dart
/// PostActionBar(
///   likeCount: post.likeCount,
///   commentCount: post.commentCount,
///   isLiked: post.isLiked,
///   isBookmarked: post.isBookmarked,
///   onLikeToggle: () => ref.read(postProvider.notifier).toggleLike(post.id),
///   onCommentTap: () => context.push('/post/${post.id}/comments'),
///   onBookmarkToggle: () => ref.read(postProvider.notifier).toggleBookmark(post.id),
/// )
/// ```
class PostActionBar extends StatelessWidget {
  /// Yeni bir [PostActionBar] oluşturur.
  const PostActionBar({
    super.key,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isBookmarked,
    this.onLikeToggle,
    this.onBookmarkToggle,
    this.onCommentTap,
    this.bookmarkCount = 0,
    this.compact = false,
  });

  /// Toplam beğeni sayısı.
  final int likeCount;

  /// Toplam yorum sayısı.
  final int commentCount;

  /// Gönderi beğenilmiş mi.
  final bool isLiked;

  /// Gönderi kaydedilmiş mi.
  final bool isBookmarked;

  /// Beğeni durumu değiştirildiğinde çağrılır.
  final VoidCallback? onLikeToggle;

  /// Kaydetme durumu değiştirildiğinde çağrılır.
  final VoidCallback? onBookmarkToggle;

  /// Yorum ikonuna dokunulduğunda çağrılır.
  final VoidCallback? onCommentTap;

  /// Toplam kaydetme sayısı.
  final int bookmarkCount;

  /// Kompakt mod — daha küçük ikonlar (20) ve dar boşluklar (12).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact
        ? AppDimensions
              .iconMedium // 20
        : AppDimensions.iconDefault; // 24
    final gap = compact ? AppDimensions.spacing12 : AppDimensions.spacing16;
    final height = compact ? 32.0 : 40.0;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          LikeButton(
            isLiked: isLiked,
            likeCount: likeCount,
            onToggle: onLikeToggle,
            size: iconSize,
          ),
          SizedBox(width: gap),
          StatCount(
            icon: Icons.chat_bubble_outline_rounded,
            count: commentCount,
            onTap: onCommentTap,
            iconColor: AppColors.comment,
            iconSize: iconSize,
          ),
          const Spacer(),
          BookmarkButton(
            isBookmarked: isBookmarked,
            onToggle: onBookmarkToggle,
            size: iconSize,
            bookmarkCount: bookmarkCount,
          ),
        ],
      ),
    );
  }
}
