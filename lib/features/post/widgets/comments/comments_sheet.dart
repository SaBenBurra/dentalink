import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/post_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/comment_provider.dart';
import '../../../../shared/utils/error_messages.dart';
import '../../../../shared/widgets/load_more_footer.dart';
import 'comment_card.dart';

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
  bool _isSubmitting = false;

  bool get _isCase => widget.post.type == PostType.casePost;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(commentsProvider(widget.post.id).notifier)
          .addComment(text);
      if (!mounted) return;
      _controller.clear();
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
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing16,
                    ),
                    itemCount: comments.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == comments.length) {
                        return LoadMoreFooter(onLoadMore: notifier.loadMore);
                      }
                      return CommentCard(
                        comment: comments[index],
                        postId: postId,
                        isPostOwner: isPostOwner,
                        isCase: _isCase,
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
                        maxLength: _commentMax,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: _isCase
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
