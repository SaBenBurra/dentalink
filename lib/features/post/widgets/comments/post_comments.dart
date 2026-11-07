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
import '../../../../shared/widgets/user_avatar.dart';
import '../../../shell/main_shell.dart';
import 'comment_card.dart';
import 'comment_thread.dart';

/// Post sayfasının gövdesi: [header] (post kartı) ve yorumlar birlikte kayar,
/// giriş alanı altta sabit kalır. Yorumların gösterildiği tek yer burası.
class PostComments extends ConsumerStatefulWidget {
  const PostComments({
    super.key,
    required this.post,
    this.header,
    this.scrollToComments = false,
    this.highlightCommentId,
  });

  final PostModel post;
  final Widget? header;

  /// Açılışta yorumların başına kaydırır (klavye açılmaz).
  final bool scrollToComments;

  /// Bildirimden gelinen yorum: yüklenince görünür yapılır ve kısa süre vurgulanır.
  /// shortcut: yalnızca yüklü üst seviye yorumlarda çalışır; yanıt bildiriminde
  /// yorumların başına kaydırır. Bildirim parent id taşıyınca yanıta da uzatılsın.
  final String? highlightCommentId;

  @override
  ConsumerState<PostComments> createState() => PostCommentsState();
}

class PostCommentsState extends ConsumerState<PostComments> {
  static const _commentMax = 2000;
  static const _highlightDuration = Duration(seconds: 2);
  late final _drafts = ref.read(commentDraftsProvider);
  late final _controller = TextEditingController(text: _drafts[widget.post.id]);
  final _focusNode = FocusNode();
  final _titleKey = GlobalKey();
  final _highlightKey = GlobalKey();
  bool _isSubmitting = false;
  late bool _highlightPending = widget.highlightCommentId != null;
  bool _highlightOn = false;

  /// Yanıt modunda yanıtlanan yorum ve gönderilince çağrılacak geri bildirim.
  ({CommentModel parent, VoidCallback onSent})? _replyTo;

  bool get _isCase => widget.post.type == PostType.casePost;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_saveDraft);
    if (widget.scrollToComments && !_highlightPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealComments());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveDraft() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      _drafts.remove(widget.post.id);
    } else {
      _drafts[widget.post.id] = text;
    }
  }

  Future<void> _revealComments() async {
    final title = _titleKey.currentContext;
    if (title == null || !mounted) return;
    await Scrollable.ensureVisible(
      title,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Post kartındaki yorum ikonu: yorumlara kayar ve klavyeyi açar.
  void focusInput() {
    _revealComments();
    _focusNode.requestFocus();
  }

  /// Yorumlar ilk yüklendiğinde bir kez çalışır.
  void _revealHighlight(List<CommentModel> comments) {
    _highlightPending = false;
    final found = comments.any((c) => c.id == widget.highlightCommentId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final target = found ? _highlightKey.currentContext : null;
      if (target == null) return _revealComments();
      if (!mounted) return;
      setState(() => _highlightOn = true);
      await Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      await Future<void>.delayed(_highlightDuration);
      if (mounted) setState(() => _highlightOn = false);
    });
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
        await commentThreadOf(
          ref,
          replyTo.parent,
        ).addReply(replyTo.parent, text);
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
    final me = ref.watch(currentUserProvider);
    final isPostOwner = me?.id == widget.post.userId;
    final colorScheme = Theme.of(context).colorScheme;

    if (_highlightPending && commentsAsync.hasValue) {
      _revealHighlight(commentsAsync.requireValue);
    }

    // Kart ve başlık tembel listede değil: kart ekrandan uzun olsa da başlığa
    // kaydırılabilir.
    final leading = SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?widget.header,
          Padding(
            key: _titleKey,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacing16,
              AppDimensions.spacing16,
              AppDimensions.spacing16,
              0,
            ),
            child: Text(
              _isCase ? l10n.discussion : l10n.commentsTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: AppDimensions.spacing24),
        ],
      ),
    );

    final Widget body = commentsAsync.when(
      data: (comments) {
        final notifier = ref.read(commentsProvider(postId).notifier);
        final hasMore = notifier.hasMore;
        if (comments.isEmpty && !hasMore) {
          return const SliverToBoxAdapter(child: CommentEmptyState());
        }
        return SliverList.separated(
          itemCount: comments.length + (hasMore ? 1 : 0),
          // Kutusuz akış: yorumlar arasında yalnızca boşluk.
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.spacing16),
          itemBuilder: (context, index) {
            if (index == comments.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing16,
                ),
                child: LoadMoreFooter(onLoadMore: notifier.loadMore),
              );
            }
            final comment = comments[index];
            final highlighted = comment.id == widget.highlightCommentId;
            return AnimatedContainer(
              key: highlighted ? _highlightKey : null,
              duration: const Duration(milliseconds: 400),
              color: highlighted && _highlightOn
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : colorScheme.primaryContainer.withValues(alpha: 0),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing16,
              ),
              child: CommentThread(
                key: ValueKey(comment.id),
                comment: comment,
                isPostOwner: isPostOwner,
                allowsBestAnswer: widget.post.type.allowsBestAnswer,
                onReply: _startReply,
                postAuthorId: widget.post.userId,
                authorBadge: _isCase
                    ? l10n.caseOwnerBadge
                    : l10n.postAuthorBadge,
              ),
            );
          },
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacing24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.commentsLoadError, style: textTheme.bodyMedium),
              TextButton(
                onPressed: () => ref.invalidate(commentsProvider(postId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              leading,
              body,
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.spacing16),
              ),
            ],
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
                  color: colorScheme.onSurfaceVariant,
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
                      color: colorScheme.onSurfaceVariant,
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
        // Bar gizlenince giriş alanı da onunla aşağı iner.
        AnimatedBuilder(
          animation: ref.watch(bottomBarAnimationProvider),
          builder: (context, child) => Padding(
            padding: EdgeInsets.only(
              bottom: bottomInsetFollowingBar(
                MediaQuery.of(context),
                ref.read(bottomBarAnimationProvider).value,
              ),
            ),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacing16,
              AppDimensions.spacing8,
              AppDimensions.spacing8,
              AppDimensions.spacing8,
            ),
            child: Row(
              children: [
                if (me != null) ...[
                  UserAvatar(
                    name: me.fullName,
                    imageUrl: me.avatarUrl,
                    size: AvatarSize.small,
                  ),
                  const SizedBox(width: AppDimensions.spacing10),
                ],
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
                          : l10n.writeComment,
                      hintStyle: textTheme.bodySmall,
                      isDense: true,
                      // En az 48dp dokunma alanı (UX-14).
                      constraints: const BoxConstraints(minHeight: 48),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing16,
                        vertical: AppDimensions.spacing12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusRound,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: textTheme.bodyMedium,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: TextButton.styleFrom(
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(l10n.share),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
