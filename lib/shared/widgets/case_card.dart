
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/shared/widgets/post_action_bar.dart';
import 'package:dentlink/shared/widgets/post_badge.dart';
import 'package:dentlink/shared/widgets/post_glass_container.dart';
import 'package:dentlink/shared/widgets/post_header.dart';
import 'package:dentlink/shared/widgets/post_media.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';
import '../../../shared/widgets/tag_chip.dart';

class CaseCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;


    return PostGlassContainer(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // <-- 1. Header yerleşimi
          PostHeader(
            post: post,
            badge: PostBadge(postType: PostType.casePost),
          ),

          // <-- 2. İçerik yerleşimi (Vaka özel iş kuralı: Max Lines 4)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  post.content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary.withValues(alpha: 0.85)
                        : AppColors.lightTextPrimary.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                  maxLines: 4, // <-- Vakalarda içerik yüksekliği farklı
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spacing12),
                if (post.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: AppDimensions.spacing6,
                    runSpacing: AppDimensions.spacing6,
                    children: post.tags
                        .map(
                          (tag) => TagChip(label: '#${tag.name}', onTap: () {}),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                ],
              ],
            ),
          ),

          // <-- 3. Görsel yerleşimi
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.3),
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
