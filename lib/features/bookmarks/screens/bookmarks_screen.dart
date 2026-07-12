import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/enums.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/post_card_factory.dart';

/// Kullanıcının kaydettiği gönderileri listeleyen ekran.
///
/// Profil → Kaydedilenler şeklinde erişilir.
/// Swipe-to-dismiss ile bookmark kaldırılabilir.
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
          if (posts.isEmpty) {
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
              itemCount: posts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDimensions.spacing8),
              itemBuilder: (context, index) {
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
                  confirmDismiss: (_) => _showRemoveConfirmation(context),
                  onDismissed: (_) {
                    ref.read(bookmarkProvider.notifier).removeBookmark(post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Kaydedilenlerden kaldırıldı'),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Geri Al',
                          textColor: const Color(0xFF13B9A5),
                          onPressed: () {
                            ref
                                .read(bookmarkProvider.notifier)
                                .toggleBookmark(post.id);
                          },
                        ),
                      ),
                    );
                  },
                  child: PostCardFactory.build(
                    post,
                    onLikeToggle: () {
                      // Bookmark ekranında like toggle feed ile senkronize
                      // olacak. Şimdilik no-op.
                    },
                    onBookmarkToggle: () {
                      ref
                          .read(bookmarkProvider.notifier)
                          .removeBookmark(post.id);
                    },
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

  Future<bool?> _showRemoveConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kayıttan Kaldır'),
        content: const Text(
          'Bu gönderiyi kaydedilenlerden kaldırmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Kaldır',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
