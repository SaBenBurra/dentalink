import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../data/models/post_model.dart';
import '../../../../shared/widgets/like_button.dart';

class PostDetailInteractionBar extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLikeToggle;
  final Widget trailing;
  
  const PostDetailInteractionBar({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          LikeButton(
            isLiked: post.isLiked,
            likeCount: post.likeCount,
            onToggle: onLikeToggle,
          ),
          const SizedBox(width: AppDimensions.spacing24),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: colorScheme.onSurfaceVariant,
                size: AppDimensions.iconDefault,
              ),
              const SizedBox(width: AppDimensions.spacing6),
              Text(
                post.commentCount.toString(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
