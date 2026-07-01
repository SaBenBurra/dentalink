import 'package:dentlink/shared/widgets/case_card.dart';
import 'package:dentlink/shared/widgets/question_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/enums.dart';
import '../../../providers/search_provider.dart';
import '../../../shared/widgets/user_tile.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

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
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.spacing8),
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
          separatorBuilder: (_, __) => const Divider(height: 1),
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
