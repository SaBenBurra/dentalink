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

/// Yorumun sağındaki kalp; sayı aksiyon satırında "N beğeni" olarak yazılır.
class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({
    super.key,
    required this.comment,
    required this.onTap,
  });
  final CommentModel comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: comment.isLiked
          ? AppLocalizations.of(context)!.unlike
          : AppLocalizations.of(context)!.like,
      onPressed: onTap,
      icon: Icon(
        comment.isLiked
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        size: comment.parentId == null ? 16 : 14,
        color: comment.isLiked ? AppColors.like : cs.outline,
      ),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Aksiyon satırındaki küçük metin butonu (Yanıtla, En İyi Cevap…).
class _CommentTextAction extends StatelessWidget {
  const _CommentTextAction({
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor:
            color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing6),
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // satır şişmesin
      ),
      child: Text(label),
    );
  }
}

/// Instagram tarzı "—— N yanıtı göster" satırı.
class _RepliesToggle extends StatelessWidget {
  const _RepliesToggle({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 24, height: 1, color: cs.outlineVariant),
            const SizedBox(width: AppDimensions.spacing8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Vaka Sahibi" / "Yazar" rozeti: yorumu postun sahibi yazdıysa.
class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing6,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: cs.primary,
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
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
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
  const CommentEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing32),
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.noCommentsYet,
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

  /// "En İyi Cevap" rozeti ve seçme butonu gösterilsin mi ([PostType.allowsBestAnswer]).
  final bool allowsBestAnswer;

  /// Null ise "Yanıtla" butonu gizli.
  final VoidCallback? onReply;

  /// Yanıtlar açık mı; [onToggleReplies] yalnızca yanıt varsa gösterilir.
  final bool repliesExpanded;
  final VoidCallback? onToggleReplies;

  /// Yorumu postun sahibi yazdıysa isminin yanında [authorBadge] gösterilir.
  final String? postAuthorId;
  final String? authorBadge;

  const CommentCard({
    super.key,
    required this.comment,
    required this.postId,
    required this.isPostOwner,
    this.allowsBestAnswer = false,
    this.postAuthorId,
    this.authorBadge,
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
          content: Text(
            unmark ? l10n.bestAnswerUnmarked : l10n.bestAnswerMarked,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getErrorMessage(AppLocalizations.of(context)!, e)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final showBest = comment.isBestAnswer && allowsBestAnswer;
    final isReply = comment.parentId != null;

    final author = comment.author;
    final authorName = author?.fullName ?? l10n.deletedUser;
    final titleName = author?.title.displayName(context) ?? '';
    final isMine = ref.watch(currentUserProvider)?.id == comment.userId;
    final isAuthor =
        authorBadge != null &&
        postAuthorId != null &&
        comment.userId == postAuthorId;
    final metaStyle = TextStyle(
      fontSize: isReply ? 10 : 11,
      color: colorScheme.onSurfaceVariant,
    );
    void openProfile() => context.push('/profile/${author!.id}');

    final avatar = UserAvatar(
      name: authorName,
      imageUrl: author?.avatarUrl,
      size: isReply ? AvatarSize.xSmall : AvatarSize.small,
    );

    final header = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.spacing6,
      children: [
        GestureDetector(
          onTap: author == null ? null : openProfile,
          child: Text(
            authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isReply ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (isAuthor) _AuthorBadge(authorBadge!),
        if (titleName.isNotEmpty)
          Text(
            '· $titleName',
            style: metaStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    final actions = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppDimensions.spacing6),
          child: RelativeTimeText(
            dateTime: comment.createdAt,
            style: metaStyle,
          ),
        ),
        if (comment.likeCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing6,
            ),
            child: Text(
              l10n.likesCount(comment.likeCount),
              style: metaStyle.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        if (onReply != null)
          _CommentTextAction(label: l10n.reply, onPressed: onReply!),
        // En iyi cevap yalnızca üst seviye yorum olabilir (026).
        if (isPostOwner && allowsBestAnswer && !isReply)
          _CommentTextAction(
            label: showBest ? l10n.unmarkSelection : l10n.markAsBestAnswer,
            onPressed: () => _handleMarkBest(context, ref),
            color: showBest ? colorScheme.onSurfaceVariant : AppColors.success,
          ),
        if (!isMine)
          ModerationMenuButton(
            target: ReportTarget.comment,
            targetId: comment.id,
            userId: comment.userId,
            postId: postId,
            compact: true,
          ),
      ],
    );

    return Container(
      padding: showBest
          ? const EdgeInsets.all(AppDimensions.spacing8)
          : EdgeInsets.zero,
      decoration: showBest
          ? BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.5),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: author != null,
            label: authorName,
            child: GestureDetector(
              onTap: author == null ? null : openProfile,
              child: avatar,
            ),
          ),
          SizedBox(
            width: isReply ? AppDimensions.spacing10 : AppDimensions.spacing12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                if (showBest)
                  const Padding(
                    padding: EdgeInsets.only(top: AppDimensions.spacing4),
                    child: _BestAnswerBadge(),
                  ),
                const SizedBox(height: AppDimensions.spacing2),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: isReply ? 11 : 12,
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
                ),
                actions,
                if (comment.replyCount > 0 && onToggleReplies != null)
                  _RepliesToggle(
                    label: repliesExpanded
                        ? l10n.hideReplies
                        : l10n.showReplies(comment.replyCount),
                    onPressed: onToggleReplies!,
                  ),
              ],
            ),
          ),
          CommentLikeButton(
            comment: comment,
            onTap: () => _handleToggleLike(context, ref),
          ),
        ],
      ),
    );
  }
}
