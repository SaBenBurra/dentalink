import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';
import '../../../domain/enums/enums.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/relative_time_text.dart';
import '../../../core/l10n/generated/app_localizations.dart';

class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.post,
    required this.badge, // <-- Post tipine özel rozet buraya enjekte edilir
    required this.subtitle,
    required this.isOwner,
    this.onMenuSelected,
  });

  final PostModel post;
  final Widget badge;
  final String subtitle;
  final bool isOwner;
  final ValueChanged<PostMenuAction>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

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
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing6),
                    Container(
                      width: AppDimensions.spacing4,
                      height: AppDimensions.spacing4,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              badge,
              const SizedBox(width: AppDimensions.spacing16),
              if (onMenuSelected != null)
                PopupMenuButton<PostMenuAction>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                  tooltip: l10n.moreOptions,
                  onSelected: onMenuSelected,
                  itemBuilder: (context) => [
                    if (isOwner)
                      PopupMenuItem(
                        value: PostMenuAction.edit,
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                    if (isOwner)
                      PopupMenuItem(
                        value: PostMenuAction.delete,
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                            const SizedBox(width: 8),
                            Text(l10n.delete, style: TextStyle(color: colorScheme.error)),
                          ],
                        ),
                      ),
                    if (!isOwner)
                      PopupMenuItem(
                        value: PostMenuAction.report,
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.report),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
