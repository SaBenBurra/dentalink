import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';
import '../../../shared/widgets/like_button.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/relative_time_text.dart';

/// Stitch "Clinical Glass" tasarımından esinlenen Soru Kartı (Question Card) widget'ı.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    this.onCommentTap,
    this.onTap,
  });

  final PostModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    return Container(
      decoration: BoxDecoration(
        color: glassBgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: glassBorderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 40,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header (Avatar, Name, Subtitle, Question Badge)
                    Row(
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
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.4),
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
                        // Question Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.secondaryContainer.withValues(
                                    alpha: 0.2,
                                  )
                                : AppColors.secondaryContainer.withValues(
                                    alpha: 0.4,
                                  ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusRound,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? colorScheme.secondary.withValues(alpha: 0.3)
                                  : AppColors.secondaryContainer,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${l10n.questionPost} ❓',
                            style: textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? colorScheme.secondaryContainer
                                  : AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // 2. Title & Content text
                    Text(
                      post.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Text(
                      post.content,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary.withValues(alpha: 0.85)
                            : AppColors.lightTextPrimary.withValues(
                                alpha: 0.85,
                              ),
                        height: 1.5,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacing16),

                    // Divider between text and action buttons
                    Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppDimensions.spacing8),

                    // 3. Action Row (Likes, Comments, Bookmark)
                    Row(
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
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusRound,
                              ),
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
                                    const SizedBox(
                                      width: AppDimensions.spacing4,
                                    ),
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
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
