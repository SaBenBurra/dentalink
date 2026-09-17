
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/shared/widgets/post_action_bar.dart';
import 'package:dentlink/shared/widgets/post_badge.dart';
import 'package:dentlink/shared/widgets/post_body.dart';
import 'package:dentlink/shared/widgets/post_glass_container.dart';
import 'package:dentlink/shared/widgets/post_header.dart';
import 'package:dentlink/shared/widgets/post_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });

  final CasePostModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;

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
            subtitle: post.branch?.displayName ?? post.author.title.displayName,
            isOwner: isOwner,
            badge: PostBadge(postType: PostType.casePost),
            onMenuSelected: (action) {
              // TODO: PostMenuAction işlemleri Faz 3'te (Supabase CRUD) bağlanacak
            },
          ),

          // <-- 2. İçerik (Vaka özel iş kuralı: maxLines 4)
          PostBody(
            title: post.title,
            content: post.content,
            tags: post.tags,
            contentMaxLines: 4,
          ),

          // <-- 3. Görsel (yoksa ayırıcı çizgi)
          if (post.imageUrls.isNotEmpty)
            PostMedia(
              imageUrls: post.imageUrls,
              isLiked: post.isLiked,
              onLikeToggle: onLikeToggle,
              onTap: onTap,
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
              post: post,
              onLikeToggle: onLikeToggle,
              onBookmarkToggle: onBookmarkToggle,
              onCommentTap: onCommentTap,
            ),
          ),
        ],
      ),
    );
  }
}
