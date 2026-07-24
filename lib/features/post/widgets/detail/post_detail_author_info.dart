import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../data/models/post_model.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/relative_time_text.dart';

class PostDetailAuthorInfo extends StatelessWidget {
  final PostModel post;
  final Widget? trailing;
  
  const PostDetailAuthorInfo({
    super.key, 
    required this.post,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
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
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
                      (post is CasePostModel ? (post as CasePostModel).branch?.displayName : null) ??
                          post.author.title.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing6),
                  const Text('•'),
                  const SizedBox(width: AppDimensions.spacing6),
                  RelativeTimeText(dateTime: post.createdAt),
                ],
              ),
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}
