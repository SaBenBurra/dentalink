import 'package:dentigo/shared/extensions/user_title_ui.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/providers/auth_provider.dart';
import 'package:dentigo/shared/widgets/post_action_bar.dart';
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
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';

class QuestionCard extends ConsumerWidget {
  const QuestionCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    this.onCommentTap,
    this.onTap,
    this.expanded = false,
  });

  final QuestionPostModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;

  /// Post sayfasında metnin tamamı gösterilir.
  final bool expanded;

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
            subtitle: post.author.title.displayName(context),
            isOwner: isOwner,
            badge: PostBadge(postType: PostType.question),
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

          // <-- 2. İçerik (uzunsa "Devamını oku")
          PostBody(
            title: post.title,
            content: post.content,
            tags: post.tags,
            expanded: expanded,
          ),

          // <-- 3. Görsel/video (yoksa ayırıcı çizgi)
          if (post.media.isNotEmpty)
            PostMedia(
              media: post.media,
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
        ],
      ),
    );
  }
}
