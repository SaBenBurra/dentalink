import 'package:dentlink/shared/widgets/case_card.dart';
import 'package:dentlink/shared/widgets/question_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

        if (posts.isEmpty) {
          return Center(
            child: Text(
              type == PostType.casePost ? 'Henüz vaka yok.' : 'Henüz soru yok.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final post = posts[index];
            if (post.type == PostType.casePost) {
              return CaseCard(
                post: post,
                onLikeToggle: () {},
                onBookmarkToggle: () {},
              );
            } else {
              return QuestionCard(
                post: post,
                onLikeToggle: () {},
                onBookmarkToggle: () {},
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Hata: $error')),
    );
  }
}
