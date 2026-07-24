import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../providers/comment_provider.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/relative_time_text.dart';

class QuestionDetailAnswers extends ConsumerWidget {
  final String postId;
  final bool isPostOwner;

  const QuestionDetailAnswers({
    super.key,
    required this.postId,
    required this.isPostOwner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    final commentsAsync = ref.watch(commentsProvider(postId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            commentsAsync.when(
              data: (comments) => Text(
                'Cevaplar (${comments.length})',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              loading: () => Text(
                'Cevaplar',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            Row(
              children: [
                Text(
                  'Sıralama: En İyi',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                child: Text(
                  'Henüz cevap yazılmamış. İlk siz cevaplayın!',
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
                final isBest = comment.isBestAnswer;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacing16),
                  decoration: BoxDecoration(
                    color: isBest
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.successLight.withValues(alpha: 0.3))
                        : glassBgColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: isBest
                        ? Border.all(color: AppColors.success, width: 1.5)
                        : Border.all(color: glassBorderColor, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.glassShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppDimensions.spacing16),
                  child: Stack(
                    children: [
                      if (isBest)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacing8,
                              vertical: AppDimensions.spacing2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: AppDimensions.spacing4),
                                Text(
                                  'En İyi Cevap',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                    Text(
                                      comment.author.fullName,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          comment.author.title.displayName,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: AppDimensions.spacing6),
                                        const Text(
                                          '•',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(width: AppDimensions.spacing6),
                                        RelativeTimeText(
                                          dateTime: comment.createdAt,
                                          style: textTheme.bodySmall?.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacing12),
                          Text(
                            comment.content,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacing16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => ref
                                        .read(commentsProvider(postId).notifier)
                                        .toggleLike(comment.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacing10,
                                        vertical: AppDimensions.spacing6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: comment.isLiked
                                            ? colorScheme.primary.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusRound,
                                        ),
                                        border: Border.all(
                                          color: comment.isLiked
                                              ? colorScheme.primary.withValues(alpha: 0.3)
                                              : Colors.transparent,
                                        ),
                                      ),
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
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isPostOwner && !isBest)
                                TextButton.icon(
                                  onPressed: () async {
                                    bool success = false;
                                    dynamic errorMsg;
                                    try {
                                      await ref
                                          .read(commentsProvider(postId).notifier)
                                          .markBestAnswer(comment.id);
                                      success = true;
                                    } catch (e) {
                                      errorMsg = e;
                                    }
                                    if (context.mounted) {
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('En iyi cevap başarıyla seçildi! 🎉'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Hata: $errorMsg')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'En İyi Cevap Seç',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.spacing12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Text('Cevaplar yüklenemedi: $err'),
        ),
      ],
    );
  }
}
