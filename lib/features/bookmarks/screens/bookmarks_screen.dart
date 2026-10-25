import 'package:flutter/material.dart';
import '../../../shared/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/enums.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/post_card_factory.dart';

/// Kullanıcının kaydettiği gönderileri listeleyen ekran.
///
/// Profil → Kaydedilenler şeklinde erişilir.
/// Kaydırarak ya da bookmark ikonuyla kaldırılır; SnackBar'dan geri alınır.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarksState = ref.watch(bookmarkProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF11211F)
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Kaydedilenler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: bookmarksState.when(
        data: (posts) {
          final notifier = ref.read(bookmarkProvider.notifier);
          final hasMore = notifier.hasMore;
          if (posts.isEmpty && !hasMore) {
            return const DentLinkEmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'Kaydedilen gönderi yok',
              subtitle:
                  'Beğendiğiniz vakaları ve soruları kaydedin,\nburadan kolayca erişin.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(bookmarkProvider.notifier).refresh(),
            color: const Color(0xFF13B9A5),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacing8,
              ),
              itemCount: posts.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDimensions.spacing8),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return LoadMoreFooter(onLoadMore: notifier.loadMore);
                }
                final post = posts[index];
                return Dismissible(
                  key: ValueKey(post.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(
                      right: AppDimensions.spacing24,
                    ),
                    color: AppColors.error.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.bookmark_remove_rounded,
                      color: AppColors.error,
                      size: AppDimensions.iconLarge,
                    ),
                  ),
                  onDismissed: (_) => _remove(context, ref, post, index),
                  child: PostCardFactory.build(
                    post,
                    onLikeToggle: () => runOrShowError(
                      context,
                      () => notifier.toggleLike(post.id),
                    ),
                    onBookmarkToggle: () => _remove(context, ref, post, index),
                    onTap: () {
                      final route = post.type == PostType.casePost
                          ? '/feed/case/${post.id}'
                          : '/feed/question/${post.id}';
                      context.push(route);
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: DentLinkErrorWidget(
            message: 'Kaydedilenler yüklenemedi.',
            onRetry: () => ref.refresh(bookmarkProvider),
          ),
        ),
      ),
    );
  }

  /// Kaydırma ve bookmark ikonu aynı yoldan geçer: hemen listeden çıkar,
  /// sunucu onaylayınca "Geri Al" sun (geri alma kaldırmayla yarışmasın).
  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
    int index,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(bookmarkProvider.notifier);
    void showError(Object e) =>
        messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(e))));

    messenger.hideCurrentSnackBar();
    try {
      await notifier.removeBookmark(post.id);
    } catch (e) {
      showError(e);
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Kaydedilenlerden kaldırıldı'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () async {
            try {
              await notifier.restoreBookmark(post, index);
            } catch (e) {
              showError(e);
            }
          },
        ),
      ),
    );
  }
}
