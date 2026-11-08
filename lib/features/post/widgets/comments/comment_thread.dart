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
typedef CommentReplyCallback =
    void Function(CommentModel parent, VoidCallback onSent);

/// Bir yorum ve (açıksa) altında girintili yanıtları; yanıtlar da aynı
/// widget'la çizildiğinden derinlik sınırsızdır.
class CommentThread extends StatefulWidget {
  const CommentThread({
    super.key,
    required this.comment,
    required this.isPostOwner,
    required this.allowsBestAnswer,
    required this.onReply,
    this.postAuthorId,
    this.authorBadge,
    this.depth = 0,
    this.parentAuthorName,
  });

  /// Bu derinlikten sonra girinti artmaz; dar ekranda metin sıkışmasın.
  static const maxIndentDepth = 4;

  final CommentModel comment;
  final bool isPostOwner;
  final bool allowsBestAnswer;
  final CommentReplyCallback onReply;
  final String? postAuthorId;
  final String? authorBadge;
  final int depth;

  /// Girinti bittiyse ([maxIndentDepth] sonrası) metnin başında "@Ad" olarak gösterilir.
  final String? parentAuthorName;

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
      allowsBestAnswer: widget.allowsBestAnswer,
      postAuthorId: widget.postAuthorId,
      authorBadge: widget.authorBadge,
      onReply: () => widget.onReply(comment, () {
        if (mounted) _setExpanded(true);
      }),
      repliesExpanded: _expanded,
      onToggleReplies: () => _setExpanded(!_expanded),
      replyToName: widget.depth > CommentThread.maxIndentDepth
          ? widget.parentAuthorName
          : null,
    );
    if (!_expanded) return card;

    // Girinti bitince çizgi de yok; yanıtın kime olduğunu "@Ad" gösterir.
    final indent = widget.depth < CommentThread.maxIndentDepth;
    final avatar = comment.parentId == null
        ? AppDimensions.avatarSmall
        : AppDimensions.avatarXSmall;
    // En iyi cevap kartı 8px iç boşlukla çizilir, avatar da o kadar kayar.
    final inset = comment.isBestAnswer && widget.allowsBestAnswer
        ? AppDimensions.spacing8
        : 0.0;
    final lineX = inset + avatar / 2;
    final replies = _Replies(
      thread: (postId: comment.postId, parentId: comment.id),
      isPostOwner: widget.isPostOwner,
      allowsBestAnswer: widget.allowsBestAnswer,
      onReply: widget.onReply,
      postAuthorId: widget.postAuthorId,
      authorBadge: widget.authorBadge,
      depth: widget.depth + 1,
      parentAuthorName: comment.author?.fullName,
      lineX: indent ? lineX : null,
      replyLeft: indent ? inset + avatar + AppDimensions.spacing8 : 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomPaint(
          // Ebeveynin avatarının altından yanıtlara inen çizgi.
          painter: indent
              ? _ThreadLinePainter(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  x: lineX,
                  top: inset + avatar + AppDimensions.spacing4,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacing4),
            child: card,
          ),
        ),
        replies,
      ],
    );
  }
}

class _Replies extends ConsumerWidget {
  const _Replies({
    required this.thread,
    required this.isPostOwner,
    required this.allowsBestAnswer,
    required this.onReply,
    required this.postAuthorId,
    required this.authorBadge,
    required this.depth,
    required this.parentAuthorName,
    required this.lineX,
    required this.replyLeft,
  });

  final ReplyThread thread;
  final bool isPostOwner;
  final bool allowsBestAnswer;
  final CommentReplyCallback onReply;
  final String? postAuthorId;
  final String? authorBadge;
  final int depth;
  final String? parentAuthorName;

  /// Ebeveynden inen çizginin x'i; null ise çizgi yok.
  final double? lineX;
  final double replyLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(repliesProvider(thread))
        .when(
          data: (replies) {
            final notifier = ref.read(repliesProvider(thread).notifier);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, reply) in replies.indexed)
                  CustomPaint(
                    key: ValueKey(reply.id),
                    // Dikey çizgiden yanıtın avatarına dirsek; son yanıtta çizgi biter.
                    painter: lineX == null
                        ? null
                        : _ThreadLinePainter(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            x: lineX!,
                            elbowY: AppDimensions.avatarXSmall / 2,
                            elbowToX: replyLeft - AppDimensions.spacing4,
                            last: i == replies.length - 1 && !notifier.hasMore,
                          ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: replyLeft,
                        bottom: AppDimensions.spacing12,
                      ),
                      child: CommentThread(
                        comment: reply,
                        isPostOwner: isPostOwner,
                        allowsBestAnswer: allowsBestAnswer,
                        onReply: onReply,
                        postAuthorId: postAuthorId,
                        authorBadge: authorBadge,
                        depth: depth,
                        parentAuthorName: parentAuthorName,
                      ),
                    ),
                  ),
                if (notifier.hasMore)
                  Padding(
                    padding: EdgeInsets.only(left: replyLeft),
                    child: LoadMoreFooter(
                      onLoadMore: notifier.loadMore,
                      auto: false,
                    ),
                  ),
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
            padding: EdgeInsets.only(
              left: replyLeft,
              bottom: AppDimensions.spacing16,
            ),
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

/// Thread çizgisi: [x]'te dikey çizgi; [elbowY] verilirse oradan [elbowToX]'e
/// yuvarlak dirsek, [last] ise çizgi dirsekte biter.
class _ThreadLinePainter extends CustomPainter {
  const _ThreadLinePainter({
    required this.color,
    required this.x,
    this.top = 0,
    this.elbowY,
    this.elbowToX = 0,
    this.last = false,
  });

  final Color color;
  final double x;
  final double top;
  final double? elbowY;
  final double elbowToX;
  final bool last;

  static const _radius = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final y = elbowY;
    if (y == null) {
      canvas.drawLine(Offset(x, top), Offset(x, size.height), paint);
      return;
    }
    final r = _radius.clamp(0.0, (elbowToX - x).clamp(0.0, y));
    canvas.drawPath(
      Path()
        ..moveTo(x, 0)
        ..lineTo(x, y - r)
        ..quadraticBezierTo(x, y, x + r, y)
        ..lineTo(elbowToX, y),
      paint,
    );
    if (!last) canvas.drawLine(Offset(x, y - r), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(_ThreadLinePainter old) =>
      old.color != color ||
      old.x != x ||
      old.top != top ||
      old.elbowY != elbowY ||
      old.elbowToX != elbowToX ||
      old.last != last;
}
