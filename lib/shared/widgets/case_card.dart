import 'package:dentlink/shared/extensions/user_title_ui.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/shared/widgets/post_action_bar.dart';
import 'package:dentlink/shared/widgets/post_badge.dart';
import 'package:dentlink/shared/widgets/post_body.dart';
import 'package:dentlink/shared/widgets/post_glass_container.dart';
import 'package:dentlink/shared/widgets/post_header.dart';
import 'package:dentlink/shared/widgets/case_treatments.dart';
import 'package:dentlink/shared/widgets/post_media.dart';
import 'package:dentlink/shared/utils/post_actions.dart';
import 'package:dentlink/shared/utils/moderation_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';

class CaseCard extends ConsumerWidget {
  const CaseCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    this.onCommentTap,
    this.onTap,
    this.expanded = false,
    this.showTreatments = true,
  });

  final CasePostModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;

  /// Post sayfasında metnin tamamı gösterilir.
  final bool expanded;

  /// Ana sayfa kartlarında tedavi satırı gösterilmez.
  final bool showTreatments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwner = currentUserId != null && currentUserId == post.author.id;

    return PostGlassContainer(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // <-- 1. Header
          PostHeader(
            post: post,
            // Branş kartta yazılmaz; tedavi çiplerinin renginde görünür.
            subtitle: post.author.title.displayName(context),
            isOwner: isOwner,
            badge: PostBadge(postType: PostType.casePost),
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

          // Listede tedaviler başlığın üstünde: vakanın "rafı".
          if (!expanded && showTreatments)
            CaseTreatmentsRow(treatments: post.treatments, onMore: onTap),

          // <-- 2. İçerik (uzunsa "Devamını oku")
          PostBody(
            title: post.title,
            content: post.content,
            tags: post.freeTags,
            expanded: expanded,
          ),

          // <-- 3. Görsel (yoksa ayırıcı çizgi)
          if (post.imageUrls.isNotEmpty)
            PostMedia(
              imageUrls: post.imageUrls,
              isLiked: post.isLiked,
              onLikeToggle: onLikeToggle,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing16,
              ),
              child: Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),

          // <-- 4. Aksiyon Butonları
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing8,
            ),
            child: PostActionBar.fromPost(
              compact: true,
              post: post,
              onLikeToggle: onLikeToggle,
              onLikesTap: () => context.push('/post/${post.id}/likes'),
              onBookmarkToggle: onBookmarkToggle,
              onCommentTap: onCommentTap,
            ),
          ),

          // <-- 5. Post sayfasında tedaviler: görselin altında, yorumların üstünde
          if (expanded) CaseTreatmentsSection(treatments: post.treatments),
        ],
      ),
    );
  }
}
