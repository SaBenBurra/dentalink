import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/post_model.dart';
import 'package:dentigo/features/feed/widgets/feed_skeleton.dart';
import 'package:dentigo/providers/feed_provider.dart';
import 'package:dentigo/shared/widgets/post_card_factory.dart';
import 'package:dentigo/shared/widgets/empty_state.dart';
import 'package:dentigo/shared/widgets/error_widget.dart';
import 'package:dentigo/shared/widgets/load_more_footer.dart';
import 'package:dentigo/shared/utils/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentigo/shared/utils/post_actions.dart';

class FeedList extends StatelessWidget {
  const FeedList({
    super.key,
    required this.ref,
    required this.context,
    required this.feedState,
    required this.filterType,
    required this.l10n,
    required this.colorScheme,
    this.controller,
    this.provider,
    this.emptyTitle,
    this.emptySubtitle,
  });

  final WidgetRef ref;
  final BuildContext context;
  final AsyncValue<dynamic> feedState;
  final PostType? filterType;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;

  /// Post listesinin kaydırması (logo ile başa dönme).
  final ScrollController? controller;

  /// Varsayılan [feedProvider]; Ticaret sekmesi [listingFeedProvider].
  final AutoDisposeAsyncNotifierProvider<FeedNotifier, List<PostModel>>?
  provider;

  final String? emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final source = provider ?? feedProvider;
    return RefreshIndicator(
      onRefresh: () => ref.read(source.notifier).refresh(),
      color: colorScheme.primary,
      child: feedState.when(
        data: (posts) {
          final filteredPosts = filterType == null
              ? posts
              : posts.where((post) => post.type == filterType).toList();

          final notifier = ref.read(source.notifier);
          final hasMore = notifier.hasMore;

          if (filteredPosts.isEmpty && !hasMore) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: DentigoEmptyState(
                      icon: Icons.dynamic_feed_outlined,
                      title: emptyTitle ?? l10n.emptyFeed,
                      subtitle:
                          emptySubtitle ??
                          (filterType != null
                              ? l10n.feedEmptyFiltered
                              : l10n.feedEmptyAll),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              0,
              AppDimensions.spacing8,
              0,
              AppDimensions.spacing8 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: filteredPosts.length + (hasMore ? 1 : 0),
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppDimensions.spacing8),
            itemBuilder: (context, index) {
              if (index == filteredPosts.length) {
                return LoadMoreFooter(onLoadMore: notifier.loadMore);
              }
              final post = filteredPosts[index];
              return PostCardFactory.build(
                post,
                onLikeToggle: () => runOrShowError(
                  context,
                  () => ref.read(source.notifier).toggleLike(post.id),
                ),
                onBookmarkToggle: () => runOrShowError(
                  context,
                  () => ref.read(source.notifier).toggleBookmark(post.id),
                ),
                onCommentTap: () => openPost(context, post, comments: true),
                onTap: () => openPost(context, post),
              );
            },
          );
        },
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [FeedSkeleton()],
        ),
        error: (err, stack) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: DentigoErrorWidget(
                message: AppLocalizations.of(context)!.feedLoadError,
                onRetry: () => ref.read(source.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
