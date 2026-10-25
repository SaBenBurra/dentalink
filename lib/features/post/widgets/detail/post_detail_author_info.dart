import 'package:dentlink/shared/extensions/dental_branch_ui.dart';
import 'package:dentlink/shared/extensions/user_title_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../data/models/post_model.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/relative_time_text.dart';
import '../../../../data/models/enums.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/utils/moderation_actions.dart';
import 'detail_states.dart';

class PostDetailAuthorInfo extends ConsumerWidget {
  final PostModel post;
  final Widget? trailing;
  
  const PostDetailAuthorInfo({
    super.key, 
    required this.post,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(currentUserProvider)?.id == post.userId;
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
          onTap: () => context.push('/profile/${post.author.id}'),
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
                      (post is CasePostModel ? (post as CasePostModel).branch?.displayName(context) : null) ??
                          post.author.title.displayName(context),
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
        if (!isOwner)
          ModerationMenuButton(
            target: ReportTarget.post,
            targetId: post.id,
            userId: post.userId,
            onBlocked: () => popOrGoFeed(context),
          ),
      ],
    );
  }
}
