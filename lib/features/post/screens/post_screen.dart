import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/post/widgets/comments/comments_sheet.dart';
import 'package:dentlink/features/post/widgets/detail/detail_states.dart';
import 'package:dentlink/providers/post_provider.dart';
import 'package:dentlink/shared/extensions/post_type_l10n.dart';
import 'package:dentlink/shared/utils/error_messages.dart';
import 'package:dentlink/shared/widgets/post_card_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tek postu feed'deki kartıyla gösterir (`/post/:id`): bildirimden, profilden,
/// aramadan, kaydedilenlerden ve ileride deep link'ten açılır.
class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({
    super.key,
    required this.postId,
    this.openComments = false,
  });

  final String postId;

  /// `?comments=1`: post yüklenince yorumlar penceresi bir kez açılır.
  final bool openComments;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  late bool _commentsPending = widget.openComments;

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
            message: getErrorMessage(l10n, e),
            onRetry: e is NotFoundFailure
                ? null
                : () => ref.invalidate(provider),
          ),
          data: (post) {
            final notifier = ref.read(provider.notifier);
            if (_commentsPending) {
              _commentsPending = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) showCommentsSheet(context, post);
              });
            }
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
                onRefresh: () => ref.refresh(provider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: AppDimensions.spacing8,
                    bottom:
                        AppDimensions.spacing8 +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    PostCardFactory.build(
                      post,
                      onLikeToggle: () =>
                          runOrShowError(context, notifier.toggleLike),
                      onBookmarkToggle: () =>
                          runOrShowError(context, notifier.toggleBookmark),
                      onCommentTap: () => showCommentsSheet(context, post),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}
