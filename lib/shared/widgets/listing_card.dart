import 'package:dentigo/shared/extensions/listing_l10n.dart';
import 'package:dentigo/shared/extensions/user_title_ui.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/providers/auth_provider.dart';
import 'package:dentigo/shared/widgets/bookmark_button.dart';
import 'package:dentigo/shared/widgets/post_badge.dart';
import 'package:dentigo/shared/widgets/post_body.dart';
import 'package:dentigo/shared/widgets/post_glass_container.dart';
import 'package:dentigo/shared/widgets/post_header.dart';
import 'package:dentigo/shared/widgets/post_media.dart';
import 'package:dentigo/shared/utils/post_actions.dart';
import 'package:dentigo/shared/utils/moderation_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/post_model.dart';

/// Ticaret ilanı kartı: fotoğraf, fiyat, durum, kategori ve şehir. Beğeni ve
/// yorum yok (052); yalnızca kaydetme. Satılan ilanda fiyatın yanında "Satıldı".
class ListingCard extends ConsumerWidget {
  const ListingCard({
    super.key,
    required this.post,
    required this.onBookmarkToggle,
    this.onTap,
    this.expanded = false,
  });

  final ListingPostModel post;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onTap;

  /// Post sayfasında açıklamanın tamamı gösterilir.
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwner = currentUserId != null && currentUserId == post.author.id;

    return PostGlassContainer(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostHeader(
            post: post,
            subtitle: post.author.title.displayName(context),
            isOwner: isOwner,
            badge: const PostBadge(postType: PostType.listing),
            onMenuSelected: (action) => switch (action) {
              PostMenuAction.edit => context.push('/edit-post/${post.id}'),
              PostMenuAction.delete => confirmAndDeletePost(
                context,
                ref,
                post.id,
              ),
              PostMenuAction.report => showReportSheet(
                context,
                ReportTarget.post,
                post.id,
              ),
              PostMenuAction.block => confirmAndBlockUser(
                context,
                ref,
                post.userId,
              ),
            },
          ),
          if (post.media.isNotEmpty)
            PostMedia(media: post.media, minAspectRatio: expanded ? 0.8 : 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacing16,
              AppDimensions.spacing12,
              AppDimensions.spacing4,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    post.priceLabel(context),
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (post.isSold) _SoldChip(),
                BookmarkButton(
                  isBookmarked: post.isBookmarked,
                  onToggle: onBookmarkToggle,
                  size: AppDimensions.iconMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
            ),
            child: Wrap(
              spacing: AppDimensions.spacing12,
              runSpacing: AppDimensions.spacing4,
              children: [
                _Meta(Icons.sell_outlined, post.condition.label(context)),
                _Meta(Icons.category_outlined, post.category.label(context)),
                _Meta(Icons.place_outlined, post.city),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          PostBody(
            title: post.title,
            content: post.content,
            tags: const [],
            expanded: expanded,
          ),
          const SizedBox(height: AppDimensions.spacing8),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconSmall, color: color),
        const SizedBox(width: AppDimensions.spacing4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SoldChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing12,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Text(
        AppLocalizations.of(context)!.listingSold,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
