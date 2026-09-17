
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/shared/widgets/post_action_bar.dart';
import 'package:dentlink/shared/widgets/post_badge.dart';
import 'package:dentlink/shared/widgets/post_body.dart';
import 'package:dentlink/shared/widgets/post_glass_container.dart';
import 'package:dentlink/shared/widgets/post_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });

  final QuestionPostModel post;
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
            subtitle: post.author.title.displayName,
            isOwner: isOwner,
            badge: PostBadge(postType: PostType.question),
            onMenuSelected: (action) {
              // TODO: PostMenuAction işlemleri Faz 3'te (Supabase CRUD) bağlanacak
            },
          ),

          // <-- 2. İçerik (Soru özel iş kuralı: maxLines 5)
          PostBody(
            title: post.title,
            content: post.content,
            tags: post.tags,
            contentMaxLines: 5,
          ),

          // <-- 3. Ayırıcı çizgi (Soru postlarında görsel eki olmadığından daima gösterilir)
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
