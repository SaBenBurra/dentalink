import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/relative_time_text.dart';

class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.post,
    required this.badge, // <-- Post tipine özel rozet buraya enjekte edilir
  });

  final PostModel post;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: post.author.fullName,
            imageUrl: post.author.avatarUrl,
            size: AvatarSize.medium,
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.fullName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.branch?.displayName ??
                            post.author.title.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing6),
                    RelativeTimeText(dateTime: post.createdAt),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          badge, // <-- Rozet burada çizilir
        ],
      ),
    );
  }
}
