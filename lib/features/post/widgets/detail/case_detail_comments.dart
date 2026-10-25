import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../providers/comment_provider.dart';
import '../../../../shared/widgets/load_more_footer.dart';
import '../comments/comment_card.dart';

class CaseDetailComments extends ConsumerWidget {
  final String postId;

  const CaseDetailComments({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final commentsAsync = ref.watch(commentsProvider(postId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.professionalDiscussion,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing16),
        commentsAsync.when(
          data: (comments) {
            final notifier = ref.read(commentsProvider(postId).notifier);
            final hasMore = notifier.hasMore;
            if (comments.isEmpty && !hasMore) {
              return const CommentEmptyState(isCase: true);
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
                  isPostOwner: false, // Vakalarda "en iyi cevap" seçimi yok
                  isCase: true,
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spacing24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) => Center(
            child: Column(
              children: [
                Text(AppLocalizations.of(context)!.commentsLoadError, style: textTheme.bodyMedium),
                TextButton(
                  onPressed: () => ref.invalidate(commentsProvider(postId)),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
