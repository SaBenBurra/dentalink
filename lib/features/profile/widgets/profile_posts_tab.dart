import 'package:dentlink/shared/widgets/post_card_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/post_model.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../providers/post_provider.dart';
import '../../../domain/enums/enums.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class ProfilePostsTab extends ConsumerWidget {
  final String userId;
  final PostType type;

  const ProfilePostsTab({super.key, required this.userId, required this.type});

  /// Profil listesi feedProvider'dan bağımsızdır; işlem repository'ye gider ve
  /// bu kullanıcının listesi yenilenir (AUDIT BUG-5).
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<PostModel> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(userPostsProvider(userId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(userPostsProvider(userId));

    return postsAsyncValue.when(
      data: (allPosts) {
        final posts = allPosts.where((p) => p.type == type).toList();

        if (posts.isEmpty) {
          return DentLinkEmptyState(
            icon: Icons.article_outlined,
            title: AppLocalizations.of(context)!.profileNoPosts,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => DentLinkErrorWidget(
        message: getErrorMessage(error),
        onRetry: () => ref.invalidate(userPostsProvider(userId)),
      ),
    );
  }
}
