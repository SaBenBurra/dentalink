import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/post_provider.dart';
import '../../../data/models/enums.dart';
import '../../feed/widgets/case_card.dart';
import '../../feed/widgets/question_card.dart';

class ProfilePostsTab extends ConsumerWidget {
  final String userId;

  const ProfilePostsTab({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(userPostsProvider(userId));

    return postsAsyncValue.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('Henüz gönderi yok.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
