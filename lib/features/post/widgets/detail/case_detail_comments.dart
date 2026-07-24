import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../providers/comment_provider.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/relative_time_text.dart';

class CaseDetailComments extends ConsumerWidget {
  final String postId;

  const CaseDetailComments({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    final commentsAsync = ref.watch(commentsProvider(postId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mesleki Tartışma',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing16),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing24),
                alignment: Alignment.center,
                child: Text(
                  'Henüz yorum yapılmamış. İlk yorumu siz ekleyin!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        name: comment.author.fullName,
                        imageUrl: comment.author.avatarUrl,
                        size: AvatarSize.small,
                      ),
                      const SizedBox(width: AppDimensions.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(AppDimensions.radiusMedium),
                                  bottomLeft: Radius.circular(AppDimensions.radiusMedium),
                                  bottomRight: Radius.circular(AppDimensions.radiusMedium),
                                ),
                                border: Border.all(
                                  color: glassBorderColor.withValues(alpha: 0.3),
                                ),
                              ),
                              padding: const EdgeInsets.all(AppDimensions.spacing12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment.author.fullName,
                                        style: textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      RelativeTimeText(
                                        dateTime: comment.createdAt,
                                        style: textTheme.bodySmall?.copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    comment.content,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Comment actions (like comment)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppDimensions.spacing4,
                                top: AppDimensions.spacing4,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => ref
                                        .read(commentsProvider(postId).notifier)
                                        .toggleLike(comment.id),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            comment.isLiked
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            size: 14,
                                            color: comment.isLiked
                                                ? AppColors.like
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            comment.likeCount.toString(),
                                            style: textTheme.bodySmall?.copyWith(
                                              fontSize: 11,
                                              color: comment.isLiked
                                                  ? AppColors.like
                                                  : colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spacing24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Text('Yorumlar yüklenemedi: $err'),
        ),
      ],
    );
  }
}
