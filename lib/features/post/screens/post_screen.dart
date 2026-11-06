import 'package:dentigo/core/constants/app_colors.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/error/app_failures.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/post_model.dart';
import 'package:dentigo/features/post/widgets/comments/post_comments.dart';
import 'package:dentigo/features/post/widgets/detail/detail_states.dart';
import 'package:dentigo/providers/comment_provider.dart';
import 'package:dentigo/providers/post_provider.dart';
import 'package:dentigo/shared/extensions/post_type_l10n.dart';
import 'package:dentigo/shared/utils/error_messages.dart';
import 'package:dentigo/shared/widgets/post_card_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tek postu kartıyla ve yorumlarıyla gösterir (`/post/:id`): feed'de karta ya
/// da yorum ikonuna dokununca, bildirimden ve linkten açılır. Vaka ve forum aynı
/// davranır; yorumlar her zaman postun altında.
class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({
    super.key,
    required this.postId,
    this.initialPost,
    this.scrollToComments = false,
    this.highlightCommentId,
  });

  final String postId;

  /// Listeden açılınca elde olan kopya: sayfa yükleniyor ekranı olmadan çizilir.
  final PostModel? initialPost;

  /// `?comments=1`: açılışta yorumlara kaydırılır.
  final bool scrollToComments;

  /// `?comment=<id>`: bildirimdeki yorum vurgulanır.
  final String? highlightCommentId;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  final _commentsKey = GlobalKey<PostCommentsState>();

  @override
  void initState() {
    super.initState();
    final seed = widget.initialPost;
    if (seed != null && !ref.exists(postDetailProvider(widget.postId))) {
      ref.read(postSeedsProvider)[widget.postId] = seed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = postDetailProvider(widget.postId);
    final l10n = AppLocalizations.of(context)!;

    // Post açıkken silinirse (kart menüsünden ya da başka cihazdan) sayfa kapanır.
    ref.listen(provider, (previous, next) {
      if (previous?.hasValue == true && next.error is NotFoundFailure) {
        popOrGoFeed(context);
      }
    });

    return ref
        .watch(provider)
        .when(
          loading: () => const PostDetailLoading(),
          error: (e, _) => PostDetailError(
            // Silinmiş ya da yazarı engellenmiş post aynı mesajı verir.
            message: e is NotFoundFailure
                ? l10n.postNotFound
                : getErrorMessage(l10n, e),
            onRetry: e is NotFoundFailure
                ? null
                : () => ref.invalidate(provider),
          ),
          data: (post) {
            final notifier = ref.read(provider.notifier);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              appBar: AppBar(
                leading: BackButton(onPressed: () => popOrGoFeed(context)),
                // Geri okunun hemen yanında (iOS’ta ortalanmaz).
                centerTitle: false,
                titleSpacing: 0,
                title: Text(post.type.getBadgeLabel(context)),
              ),
              body: RefreshIndicator(
                onRefresh: () {
                  ref.invalidate(commentsProvider(post.id));
                  return ref.refresh(provider.future);
                },
                child: PostComments(
                  key: _commentsKey,
                  post: post,
                  scrollToComments: widget.scrollToComments,
                  highlightCommentId: widget.highlightCommentId,
                  header: Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.spacing8),
                    child: PostCardFactory.build(
                      post,
                      expanded: true,
                      onLikeToggle: () =>
                          runOrShowError(context, notifier.toggleLike),
                      onBookmarkToggle: () =>
                          runOrShowError(context, notifier.toggleBookmark),
                      onCommentTap: () =>
                          _commentsKey.currentState?.focusInput(),
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }
}
