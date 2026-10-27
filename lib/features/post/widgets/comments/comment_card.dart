import 'package:dentlink/shared/extensions/user_title_ui.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../data/models/comment_model.dart';
import '../../../../../providers/comment_provider.dart';
import '../../../../../shared/widgets/user_avatar.dart';
import '../../../../../shared/widgets/relative_time_text.dart';
import '../../../../../shared/utils/error_messages.dart';
import '../../../../../shared/utils/moderation_actions.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../data/models/enums.dart';

class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({super.key, required this.comment, required this.onTap});
  final CommentModel comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = comment.isLiked ? AppColors.like : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      label: comment.isLiked ? AppLocalizations.of(context)!.unlike : AppLocalizations.of(context)!.like,
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

/// Yorumun aksiyon satırındaki küçük metinli buton (Yanıtla, yanıtları göster).
class _CommentTextAction extends StatelessWidget {
  const _CommentTextAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(
        foregroundColor: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing8),
        minimumSize: const Size(40, 40), // 40px touch target
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
            AppLocalizations.of(context)!.bestAnswer,
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
        isCase ? AppLocalizations.of(context)!.noCommentsYet : AppLocalizations.of(context)!.noAnswersYet,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class CommentCard extends ConsumerWidget {
  final CommentModel comment;
  final String postId;
  final bool isPostOwner;
  final bool isCase;

  /// Null ise "Yanıtla" butonu gizli.
  final VoidCallback? onReply;

  /// Yanıtlar açık mı; [onToggleReplies] yalnızca yanıt varsa gösterilir.
  final bool repliesExpanded;
  final VoidCallback? onToggleReplies;

  const CommentCard({
    super.key,
    required this.comment,
    required this.postId,
    required this.isPostOwner,
    this.isCase = false,
    this.onReply,
    this.repliesExpanded = false,
    this.onToggleReplies,
  });

  Future<void> _handleMarkBest(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(commentsProvider(postId).notifier);
    final unmark = comment.isBestAnswer;
    try {
      if (unmark) {
        await notifier.unmarkBestAnswer(comment.id);
      } else {
        await notifier.markBestAnswer(comment.id);
      }
      scaffold.showSnackBar(
        SnackBar(
          content: Text(unmark
              ? l10n.bestAnswerUnmarked
              : l10n.bestAnswerMarked),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
    }
  }
  
  Future<void> _handleToggleLike(BuildContext context, WidgetRef ref) async {
    try {
      await commentThreadOf(ref, comment).toggleLike(comment.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getErrorMessage(AppLocalizations.of(context)!, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final showBest = comment.isBestAnswer && !isCase;

    final authorName = comment.author?.fullName ?? l10n.deletedUser;
    final titleName = comment.author?.title.displayName(context) ?? '';
    final isMine = ref.watch(currentUserProvider)?.id == comment.userId;
    final metaStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontSize: 11,
    );

    // Tek satırlık başlık: avatar, isim · unvan · zaman ve menü aynı eksende ortalı.
    final header = SizedBox(
      height: kMinInteractiveDimension, // menü butonunun dokunma alanı
      child: Row(
        children: [
          UserAvatar(
            name: authorName,
            imageUrl: comment.author?.avatarUrl,
            size: AvatarSize.small,
            onTap: comment.author == null
                ? null
                : () => context.push('/profile/${comment.author!.id}'),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Expanded(
            child: Row(
              children: [
                // Uzun isim önce unvanı keser; zaman her zaman görünür.
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: authorName,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      children: [
                        if (titleName.isNotEmpty)
                          TextSpan(text: ' · $titleName', style: metaStyle),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(' · ', style: metaStyle),
                RelativeTimeText(dateTime: comment.createdAt, style: metaStyle),
              ],
            ),
          ),
          if (!isMine)
            ModerationMenuButton(
              target: ReportTarget.comment,
              targetId: comment.id,
              userId: comment.userId,
              postId: postId,
            ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing4),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing8),
      decoration: showBest
          ? BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (showBest)
            const Padding(
              padding: EdgeInsets.only(bottom: AppDimensions.spacing4),
              child: _BestAnswerBadge(),
            ),
          Text(
            comment.content,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          Row(
            children: [
              // Derin yanıtlarda dar kalınca alt satıra geçer.
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CommentLikeButton(
                      comment: comment,
                      onTap: () => _handleToggleLike(context, ref),
                    ),
                    if (onReply != null)
                      _CommentTextAction(
                        icon: Icons.reply_rounded,
                        label: l10n.reply,
                        onPressed: onReply!,
                      ),
                    if (comment.replyCount > 0 && onToggleReplies != null)
                      _CommentTextAction(
                        icon: repliesExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        label: repliesExpanded
                            ? l10n.hideReplies
                            : l10n.showReplies(comment.replyCount),
                        onPressed: onToggleReplies!,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
              ),
              // En iyi cevap yalnızca üst seviye yorum olabilir (026).
              if (isPostOwner && !isCase && comment.parentId == null)
                _CommentTextAction(
                  icon: showBest ? Icons.close_rounded : Icons.verified_rounded,
                  label: showBest ? l10n.unmarkSelection : l10n.markAsBestAnswer,
                  onPressed: () => _handleMarkBest(context, ref),
                  color: showBest ? colorScheme.onSurfaceVariant : AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
