import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../providers/comment_provider.dart';
import '../../../../providers/post_provider.dart';
import '../../../../shared/widgets/load_more_footer.dart';
import '../comments/comment_card.dart';

class QuestionDetailAnswers extends ConsumerWidget {
  final String postId;
  final bool isPostOwner;

  const QuestionDetailAnswers({
    super.key,
    required this.postId,
    required this.isPostOwner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final commentsAsync = ref.watch(commentsProvider(postId));
    // Yorumlar sayfalı; toplam postun sayacından gelir.
    final total = ref.watch(
      postDetailProvider(postId).select((p) => p.valueOrNull?.commentCount),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            commentsAsync.when(
              data: (comments) => Text(
                'Cevaplar (${total ?? comments.length})',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              loading: () => Text(
                'Cevaplar',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),
        commentsAsync.when(
          data: (comments) {
            final notifier = ref.read(commentsProvider(postId).notifier);
            final hasMore = notifier.hasMore;
            if (comments.isEmpty && !hasMore) {
              return const CommentEmptyState(isCase: false);
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == comments.length) {
                  return LoadMoreFooter(onLoadMore: notifier.loadMore, auto: false);
                }
                return CommentCard(
                  comment: comments[index],
                  postId: postId,
                  isPostOwner: isPostOwner,
                  isCase: false,
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spacing32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Center(
            child: Column(
              children: [
                Text('Cevaplar yüklenemedi.', style: textTheme.bodyMedium),
                TextButton(
                  onPressed: () => ref.invalidate(commentsProvider(postId)),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
