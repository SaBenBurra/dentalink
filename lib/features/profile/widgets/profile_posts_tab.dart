import 'package:dentlink/providers/feed_provider.dart';
import 'package:dentlink/shared/widgets/post_card_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/post_provider.dart';
import '../../../data/models/enums.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class ProfilePostsTab extends ConsumerWidget {
  final String userId;
  final PostType type;

  const ProfilePostsTab({super.key, required this.userId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(userPostsProvider(userId));

    return postsAsyncValue.when(
      data: (allPosts) {
        final posts = allPosts.where((p) => p.type == type).toList();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final post = posts[index];

            // Profil sayfasına özel rota hesaplaması // <-- Eklendi
            // Not: Projenizdeki GoRouter tanımlamalarına göre prefix (örn: /profile) değiştirilebilir.
            final routePath = post.type == PostType.casePost
                ? '/profile/case/${post.id}'
                : '/profile/question/${post.id}';

            return PostCardFactory.build(
              post,
              // userPostsProvider yerine global etkileşim metodunu barındıran provider çağrılır // <--
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Hata: $error')),
    );
  }
}
