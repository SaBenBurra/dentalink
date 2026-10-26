import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/features/feed/widgets/feed_skeleton.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:dentlink/shared/widgets/post_card_factory.dart';
import 'package:dentlink/shared/widgets/empty_state.dart';
import 'package:dentlink/shared/widgets/error_widget.dart';
import 'package:dentlink/shared/widgets/load_more_footer.dart';
import 'package:dentlink/shared/utils/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentlink/features/post/widgets/comments/comments_sheet.dart';

class FeedList extends StatelessWidget {
  const FeedList({
    super.key,
    required this.ref,
    required this.context,
    required this.feedState,
    required this.filterType,
    required this.l10n,
    required this.colorScheme,
  });

  final WidgetRef ref;
  final BuildContext context;
  final AsyncValue<dynamic> feedState;
  final PostType? filterType;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: colorScheme.primary,
      child: feedState.when(
        data: (posts) {
          final filteredPosts = filterType == null
              ? posts
              : posts.where((post) => post.type == filterType).toList();

          final notifier = ref.read(feedProvider.notifier);
          final hasMore = notifier.hasMore;

          if (filteredPosts.isEmpty && !hasMore) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: DentLinkEmptyState(
                      icon: Icons.dynamic_feed_outlined,
                      title: l10n.emptyFeed,
                      subtitle: filterType != null
                          ? l10n.feedEmptyFiltered
                          : l10n.feedEmptyAll,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
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
                  () => ref.read(feedProvider.notifier).toggleLike(post.id),
                ),
                onBookmarkToggle: () => runOrShowError(
                  context,
                  () => ref.read(feedProvider.notifier).toggleBookmark(post.id),
                ),
                onCommentTap: () => showCommentsSheet(context, post),
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
              child: DentLinkErrorWidget(
                message: AppLocalizations.of(context)!.feedLoadError,
                onRetry: () => ref.read(feedProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
