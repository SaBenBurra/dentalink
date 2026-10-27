import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../data/models/comment_model.dart';
import '../../../../providers/comment_provider.dart';
import '../../../../shared/widgets/load_more_footer.dart';
import 'comment_card.dart';

/// "Yanıtla"ya basılınca çağrılır; [onSent] yanıt gönderilince çağrılmalı
/// (ebeveynin yanıtları açılır).
typedef CommentReplyCallback = void Function(
  CommentModel parent,
  VoidCallback onSent,
);

/// Bir yorum ve (açıksa) altında girintili yanıtları; yanıtlar da aynı
/// widget'la çizildiğinden derinlik sınırsızdır.
class CommentThread extends StatefulWidget {
  const CommentThread({
    super.key,
    required this.comment,
    required this.isPostOwner,
    required this.isCase,
    required this.onReply,
    this.depth = 0,
  });

  /// Bu derinlikten sonra girinti artmaz; dar ekranda metin sıkışmasın.
  static const maxIndentDepth = 4;

  final CommentModel comment;
  final bool isPostOwner;
  final bool isCase;
  final CommentReplyCallback onReply;
  final int depth;

  @override
  State<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<CommentThread>
    with AutomaticKeepAliveClientMixin {
  bool _expanded = false;

  // Açık thread listeden kayınca yanıtları yeniden yüklenmesin.
  @override
  bool get wantKeepAlive => _expanded;

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    setState(() => _expanded = value);
    updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final comment = widget.comment;
    final card = CommentCard(
      comment: comment,
      postId: comment.postId,
      isPostOwner: widget.isPostOwner,
      isCase: widget.isCase,
      onReply: () => widget.onReply(comment, () {
        if (mounted) _setExpanded(true);
      }),
      repliesExpanded: _expanded,
      onToggleReplies: () => _setExpanded(!_expanded),
    );
    if (!_expanded) return card;

    final indent = widget.depth < CommentThread.maxIndentDepth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Padding(
          // Çizgi ebeveynin avatar merkezinden iner (kart iç boşluğu + avatar/2).
          padding: EdgeInsets.only(
            left: indent
                ? AppDimensions.spacing8 + AppDimensions.avatarSmall / 2 - 1
                : 0,
          ),
          child: DecoratedBox(
            // Reddit tarzı thread çizgisi.
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: AppDimensions.spacing8),
              child: _Replies(
                thread: (postId: comment.postId, parentId: comment.id),
                isPostOwner: widget.isPostOwner,
                isCase: widget.isCase,
                onReply: widget.onReply,
                depth: widget.depth + 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Replies extends ConsumerWidget {
  const _Replies({
    required this.thread,
    required this.isPostOwner,
    required this.isCase,
    required this.onReply,
    required this.depth,
  });

  final ReplyThread thread;
  final bool isPostOwner;
  final bool isCase;
  final CommentReplyCallback onReply;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref.watch(repliesProvider(thread)).when(
          data: (replies) {
            final notifier = ref.read(repliesProvider(thread).notifier);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final reply in replies)
                  CommentThread(
                    key: ValueKey(reply.id),
                    comment: reply,
                    isPostOwner: isPostOwner,
                    isCase: isCase,
                    onReply: onReply,
                    depth: depth,
                  ),
                if (notifier.hasMore)
                  LoadMoreFooter(onLoadMore: notifier.loadMore, auto: false),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.spacing16),
            child: Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.commentsLoadError,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(repliesProvider(thread)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        );
  }
}
