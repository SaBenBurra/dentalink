import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/post/widgets/comments/comments_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/search_provider.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/user_tile.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/load_more_footer.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/shared/widgets/post_card_factory.dart';

class PostSearchResults extends ConsumerWidget {
  const PostSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    return state.postResults.when(
      data: (posts) {
        final notifier = ref.read(searchProvider.notifier);
        final hasMore = notifier.hasMore;
        if (posts.isEmpty && !hasMore) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: AppDimensions.spacing64),
              child: DentLinkEmptyState(
                icon: Icons.article_outlined,
                title: AppLocalizations.of(context)!.searchNoResultsTitle,
                subtitle: AppLocalizations.of(context)!.searchNoPosts,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.only(
            top: AppDimensions.spacing8,
            bottom: AppDimensions.spacing8 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: posts.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.spacing8),
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return LoadMoreFooter(onLoadMore: notifier.loadMore);
            }
            final post = posts[index];
            final routePath = '/post/${post.id}';

            return PostCardFactory.build(
              post,
              onLikeToggle: () => runOrShowError(
                context,
                () => ref.read(searchProvider.notifier).toggleLike(post.id),
              ),
              onBookmarkToggle: () => runOrShowError(
                context,
                () => ref.read(searchProvider.notifier).toggleBookmark(post.id),
              ),
              onCommentTap: () => showCommentsSheet(context, post),
              onTap: () => context.push(routePath),
            );
          },
        );
      },
      loading: () => const DentLinkLoadingSpinner(),
      error: (err, stack) {
        final msg = getErrorMessage(AppLocalizations.of(context)!, err);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(msg),
              TextButton(
                onPressed: () => ref.read(searchProvider.notifier).search(ref.read(searchProvider).query),
                child: Text(AppLocalizations.of(context)!.retry),
              )
            ],
          ),
        );
      },
    );
  }
}

class UserSearchResults extends ConsumerWidget {
  const UserSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    return state.userResults.when(
      data: (users) {
        if (users.isEmpty) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: AppDimensions.spacing64),
              child: DentLinkEmptyState(
                icon: Icons.people_outline,
                title: AppLocalizations.of(context)!.searchNoResultsTitle,
                subtitle: AppLocalizations.of(context)!.searchNoUsers,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.only(
            top: AppDimensions.spacing8,
            bottom: AppDimensions.spacing8 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: users.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return UserTile(
              user: user,
              onTap: () => context.push('/profile/${user.id}'),
            );
          },
        );
      },
      loading: () => const DentLinkLoadingSpinner(),
      error: (err, stack) {
        final msg = getErrorMessage(AppLocalizations.of(context)!, err);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(msg),
              TextButton(
                onPressed: () => ref.read(searchProvider.notifier).search(ref.read(searchProvider).query),
                child: Text(AppLocalizations.of(context)!.retry),
              )
            ],
          ),
        );
      },
    );
  }
}
