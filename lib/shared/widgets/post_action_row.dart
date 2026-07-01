import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';
import '../../../shared/widgets/like_button.dart';
import '../../../shared/widgets/bookmark_button.dart';

class PostActionRow extends StatelessWidget {
  const PostActionRow({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    this.onCommentTap,
  });

  final PostModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onCommentTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              LikeButton(
                isLiked: post.isLiked,
                likeCount: post.likeCount,
                onToggle: onLikeToggle,
              ),
              const SizedBox(width: AppDimensions.spacing16),
              InkWell(
                onTap: onCommentTap,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacing8,
                    horizontal: AppDimensions.spacing4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: AppDimensions.iconDefault,
                      ),
                      const SizedBox(width: AppDimensions.spacing4),
                      Text(
                        post.commentCount.toString(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          BookmarkButton(
            isBookmarked: post.isBookmarked,
            onToggle: onBookmarkToggle,
            bookmarkCount: post.bookmarkCount,
            showCount: false,
          ),
        ],
      ),
    );
  }
}
