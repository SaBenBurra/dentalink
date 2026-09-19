import 'package:dentlink/shared/widgets/case_card.dart';
import 'package:dentlink/shared/widgets/question_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/enums.dart';
import '../../../data/models/post_model.dart';
import '../../../providers/search_provider.dart';
import '../../../shared/widgets/user_tile.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/shared/widgets/post_card_factory.dart';

class PostSearchResults extends ConsumerWidget {
  const PostSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    return state.postResults.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: AppDimensions.spacing64),
              child: DentLinkEmptyState(
                icon: Icons.article_outlined,
                title: 'Sonuç Bulunamadı',
                subtitle: 'Arama kriterlerinize uygun gönderi bulunamadı.',
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          itemCount: posts.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.spacing8),
          itemBuilder: (context, index) {
            final post = posts[index];
            final routePath = post.type == PostType.casePost
                ? '/feed/case/${post.id}'
                : '/feed/question/${post.id}';

            return PostCardFactory.build(
              post,
              onLikeToggle: () => ref.read(searchProvider.notifier).toggleLike(post.id),
              onBookmarkToggle: () => ref.read(searchProvider.notifier).toggleBookmark(post.id),
              onCommentTap: () => context.push(routePath),
              onTap: () => context.push(routePath),
            );
          },
        );
      },
      loading: () => const DentLinkLoadingSpinner(),
      error: (err, stack) => Center(child: Text('Hata: $err')),
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
          return const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: AppDimensions.spacing64),
              child: DentLinkEmptyState(
                icon: Icons.people_outline,
                title: 'Sonuç Bulunamadı',
                subtitle: 'Arama kriterlerinize uygun kullanıcı bulunamadı.',
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          itemCount: users.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return UserTile(user: user);
          },
        );
      },
      loading: () => const DentLinkLoadingSpinner(),
      error: (err, stack) => Center(child: Text('Hata: $err')),
    );
  }
}
