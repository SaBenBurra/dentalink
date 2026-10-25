import 'package:dentlink/shared/widgets/post_card_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/post_model.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../providers/post_provider.dart';
import '../../../data/models/enums.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/load_more_footer.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class ProfilePostsTab extends ConsumerWidget {
  final String userId;
  final PostType type;

  const ProfilePostsTab({super.key, required this.userId, required this.type});

  /// Profil listesi feedProvider'dan bağımsızdır; işlem repository'ye gider ve
  /// listedeki post sunucunun döndüğüyle değişir (AUDIT BUG-5); yüklenen
  /// sayfalar korunur.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<PostModel> Function() action,
  ) async {
    final notifier = ref.read(userPostsProvider(userId).notifier);
    try {
      final updated = await action();
      notifier.patchPost(updated.id, (_) => updated);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(getErrorMessage(AppLocalizations.of(context)!, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(userPostsProvider(userId));

    return postsAsyncValue.when(
      data: (allPosts) {
        final posts = allPosts.where((p) => p.type == type).toList();

        final notifier = ref.read(userPostsProvider(userId).notifier);
        final hasMore = notifier.hasMore;

        if (posts.isEmpty && !hasMore) {
          return DentLinkEmptyState(
            icon: Icons.article_outlined,
            title: AppLocalizations.of(context)!.profileNoPosts,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(userPostsProvider(userId).future),
          child: ListView.separated(
            padding: EdgeInsets.only(
              top: AppDimensions.spacing8,
              bottom: AppDimensions.spacing8 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: posts.length + (hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return LoadMoreFooter(onLoadMore: notifier.loadMore);
              }
              final post = posts[index];

              final routePath = post.type == PostType.casePost
                  ? '/feed/case/${post.id}'
                  : '/feed/question/${post.id}';

              return PostCardFactory.build(
                post,
                onLikeToggle: () => _run(context, ref, () {
                  final repo = ref.read(postActionRepositoryProvider);
                  return post.isLiked ? repo.unlikePost(post.id) : repo.likePost(post.id);
                }),
                onBookmarkToggle: () => _run(context, ref, () {
                  final repo = ref.read(bookmarkRepositoryProvider);
                  return post.isBookmarked
                      ? repo.unbookmarkPost(post.id)
                      : repo.bookmarkPost(post.id);
                }),
                onCommentTap: () => context.push(routePath),
                onTap: () => context.push(routePath),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => DentLinkErrorWidget(
        message: getErrorMessage(AppLocalizations.of(context)!, error),
        onRetry: () => ref.invalidate(userPostsProvider(userId)),
      ),
    );
  }
}
