import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../domain/entities/comment_entity.dart';
import '../../../../../providers/comment_provider.dart';
import '../../../../../shared/widgets/user_avatar.dart';
import '../../../../../shared/widgets/relative_time_text.dart';
import '../../../../../shared/utils/error_messages.dart';

class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({super.key, required this.comment, required this.onTap});
  final CommentEntity comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = comment.isLiked ? AppColors.like : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      label: comment.isLiked ? 'Beğeniyi geri al' : 'Beğen',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: AppDimensions.spacing4),
              Text(
                '${comment.likeCount}',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: comment.isLiked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestAnswerBadge extends StatelessWidget {
  const _BestAnswerBadge();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
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
    );
  }
}

class CommentEmptyState extends StatelessWidget {
  final bool isCase;
  const CommentEmptyState({super.key, this.isCase = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing32),
      alignment: Alignment.center,
      child: Text(
        isCase ? 'Henüz yorum yapılmamış. İlk yorumu siz ekleyin!' : 'Henüz cevap yazılmamış. İlk siz cevaplayın!',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class CommentCard extends ConsumerWidget {
  final CommentEntity comment;
  final String postId;
  final bool isPostOwner;
  final bool isCase; 

  const CommentCard({
    super.key,
    required this.comment,
    required this.postId,
    required this.isPostOwner,
    this.isCase = false,
  });

  Future<void> _handleMarkBest(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await ref.read(commentsProvider(postId).notifier).markBestAnswer(comment.id);
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('En iyi cevap başarıyla seçildi! 🎉'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
    }
  }
  
  Future<void> _handleToggleLike(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(commentsProvider(postId).notifier).toggleLike(comment.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isBest = comment.isBestAnswer;
    final showBest = isBest && !isCase;

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);
        
    final authorName = comment.author?.fullName ?? '[Silinmiş Kullanıcı]';
    final avatarUrl = comment.author?.avatarUrl;
    final titleName = comment.author?.title.displayName ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: showBest
            ? (isDark
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.successLight.withValues(alpha: 0.3))
            : (isCase 
                ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)) 
                : glassBgColor),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: showBest
              ? AppColors.success
              : (isCase ? glassBorderColor.withValues(alpha: 0.3) : glassBorderColor),
          width: showBest ? 1.5 : 1,
        ),
        boxShadow: isCase ? null : const [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: authorName,
                    imageUrl: avatarUrl,
                    size: AvatarSize.small,
                  ),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              authorName,
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (isCase) 
                              RelativeTimeText(
                                dateTime: comment.createdAt,
                                style: textTheme.bodySmall?.copyWith(fontSize: 11),
                              ),
                            if (showBest)
                              const _BestAnswerBadge(),
                          ],
                        ),
                        if (!isCase)
                          Row(
                            children: [
                              Text(
                                titleName,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacing6),
                              const Text('•', style: TextStyle(fontSize: 11)),
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
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CommentLikeButton(
                    comment: comment,
                    onTap: () => _handleToggleLike(context, ref),
                  ),
                  if (isPostOwner && !showBest && !isCase)
                    TextButton.icon(
                      onPressed: () => _handleMarkBest(context, ref),
                      icon: const Icon(Icons.verified_rounded, size: 14),
                      label: const Text('En İyi Cevap Seç', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing12),
                        minimumSize: const Size(40, 40), // 40px touch target
                      ),
                    ),
                ],
              ),
            ],
          ),
    );
  }
}
