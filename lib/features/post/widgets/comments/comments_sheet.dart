import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../data/models/comment_model.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/post_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/comment_provider.dart';
import '../../../../shared/utils/error_messages.dart';
import '../../../../shared/widgets/load_more_footer.dart';
import 'comment_card.dart';
import 'comment_thread.dart';

/// Feed kartındaki yorum ikonundan açılan yorumlar penceresi.
void showCommentsSheet(BuildContext context, PostModel post) {
  showModalBottomSheet<void>(
    context: context,
    // Alt menünün de üstünü kaplar.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => CommentsSheet(post: post),
  );
}

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.post});

  final PostModel post;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  static const _commentMax = 2000;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  /// Yanıt modunda yanıtlanan yorum ve gönderilince çağrılacak geri bildirim.
  ({CommentModel parent, VoidCallback onSent})? _replyTo;

  bool get _isCase => widget.post.type == PostType.casePost;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startReply(CommentModel parent, VoidCallback onSent) {
    setState(() => _replyTo = (parent: parent, onSent: onSent));
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final replyTo = _replyTo;
      if (replyTo == null) {
        await ref
            .read(commentsProvider(widget.post.id).notifier)
            .addComment(text);
      } else {
        await commentThreadOf(ref, replyTo.parent)
            .addReply(replyTo.parent, text);
        replyTo.onSent();
      }
      if (!mounted) return;
      _controller.clear();
      setState(() => _replyTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getErrorMessage(AppLocalizations.of(context)!, e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final postId = widget.post.id;
    final commentsAsync = ref.watch(commentsProvider(postId));
    final isPostOwner =
        ref.watch(currentUserProvider)?.id == widget.post.userId;

    return Padding(
      // Klavye açılınca giriş alanı üstte kalsın.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: double.infinity, // durum çubuğu altına kadar tam ekran
        child: Column(
          children: [
            Text(
              _isCase ? l10n.discussion : l10n.answersTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: AppDimensions.spacing24),
            Expanded(
              child: commentsAsync.when(
                data: (comments) {
                  final notifier = ref.read(commentsProvider(postId).notifier);
                  final hasMore = notifier.hasMore;
                  if (comments.isEmpty && !hasMore) {
                    return SingleChildScrollView(
                      child: CommentEmptyState(isCase: _isCase),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing16,
                    ),
                    itemCount: comments.length + (hasMore ? 1 : 0),
                    // Yalnızca alt pay: üstteki boşluğu beğeni satırının iç payı (12dp) veriyor,
                    // böylece çizgiden yoruma iki yönde de 12dp kalıyor.
                    separatorBuilder: (_, _) =>
                        const Padding(
                          padding: EdgeInsets.only(bottom: AppDimensions.spacing8),
                          child: Divider(height: 1),
                        ),
                    itemBuilder: (context, index) {
                      if (index == comments.length) {
                        return LoadMoreFooter(onLoadMore: notifier.loadMore);
                      }
                      final comment = comments[index];
                      return CommentThread(
                        key: ValueKey(comment.id),
                        comment: comment,
                        isPostOwner: isPostOwner,
                        isCase: _isCase,
                        onReply: _startReply,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isCase
                            ? l10n.commentsLoadError
                            : l10n.answersLoadError,
                        style: textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(commentsProvider(postId)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            if (_replyTo case final replyTo?)
              Padding(
                padding: const EdgeInsets.only(left: AppDimensions.spacing16),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Expanded(
                      child: Text(
                        l10n.replyingTo(
                          replyTo.parent.author?.fullName ?? l10n.deletedUser,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.cancel,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _replyTo = null),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacing16,
                  AppDimensions.spacing4,
                  AppDimensions.spacing4,
                  AppDimensions.spacing4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLength: _commentMax,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: _replyTo != null
                              ? l10n.writeReply
                              : _isCase
                              ? l10n.joinDiscussionHint
                              : l10n.writeAnswer,
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.sendMessage,
                      icon: const Icon(Icons.send_rounded),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
