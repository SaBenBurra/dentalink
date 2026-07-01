import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/features/feed/widgets/feed_skeleton.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:dentlink/shared/widgets/post_card_factory.dart';
import 'package:dentlink/shared/widgets/empty_state.dart';
import 'package:dentlink/shared/widgets/error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

          if (filteredPosts.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: DentLinkEmptyState(
                      icon: Icons.dynamic_feed_outlined,
                      title: l10n.emptyFeed,
                      subtitle: filterType != null
                          ? 'Seçili filtreye uygun gönderi bulunamadı.'
                          : 'Akışta henüz hiç paylaşım yapılmamış.',
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing12,
            ),
            itemCount: filteredPosts.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppDimensions.spacing16),
            itemBuilder: (context, index) {
              final post = filteredPosts[index];

              final routePath = post.type == PostType.casePost
                  ? '/feed/case/${post.id}'
                  : '/feed/question/${post.id}';

              return PostCardFactory.build(
                post,
                onLikeToggle: () =>
                    ref.read(feedProvider.notifier).toggleLike(post.id),
                onBookmarkToggle: () =>
                    ref.read(feedProvider.notifier).toggleBookmark(post.id),
                onCommentTap: () => context.push(routePath),
                onTap: () => context.push(routePath),
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
                message: 'Akış yüklenirken bir hata oluştu.',
                onRetry: () => ref.read(feedProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
