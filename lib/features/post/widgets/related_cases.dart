import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/post_model.dart';
import '../../../providers/treatment_archive_provider.dart';
import '../../../shared/extensions/dental_branch_ui.dart';
import '../../../shared/extensions/treatment_type_ui.dart';
import '../../../shared/utils/post_actions.dart';
import '../../../shared/widgets/post_glass_container.dart';

/// Post sayfasında kartın altında "Benzer vakalar": ortak tedavisi en çok
/// olanlar önce, yana kayan küçük kartlar. Yoksa ya da yüklenemezse hiç
/// görünmez (yardımcı bölüm; yorumlara geçişi engellemez).
class RelatedCases extends ConsumerWidget {
  const RelatedCases({super.key, required this.postId});

  final String postId;

  static const _tileWidth = 200.0;
  static const _imageHeight = 110.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(relatedCasesProvider(postId)).valueOrNull;
    if (posts == null || posts.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacing16,
            AppDimensions.spacing16,
            AppDimensions.spacing16,
            AppDimensions.spacing8,
          ),
          child: Semantics(
            header: true,
            child: Text(
              AppLocalizations.of(context)!.relatedCases,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(
          height: _imageHeight + 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
            ),
            itemCount: posts.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppDimensions.spacing8),
            itemBuilder: (context, i) => SizedBox(
              width: _tileWidth,
              child: _RelatedTile(post: posts[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _RelatedTile extends StatelessWidget {
  const _RelatedTile({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final (image, treatment) = switch (post) {
      CasePostModel(:final imageUrls, :final treatments) => (
        imageUrls.firstOrNull,
        treatments.firstOrNull,
      ),
      _ => (null, null),
    };
    return PostGlassContainer(
      onTap: () => openPost(context, post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusMedium),
            ),
            child: SizedBox(
              height: RelatedCases._imageHeight,
              child: image == null
                  ? ColoredBox(color: colorScheme.surfaceContainerHighest)
                  : CachedNetworkImage(
                      imageUrl: image,
                      // İmzalı URL her çekişte değişir; önbellek dosya yoluna bağlı (SEC-9).
                      cacheKey: Uri.parse(image).path,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge,
                ),
                if (treatment != null) ...[
                  const SizedBox(height: AppDimensions.spacing4),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: treatment.branch.colorOf(context),
                      ),
                      const SizedBox(width: AppDimensions.spacing4),
                      Expanded(
                        child: Text(
                          treatment.displayName(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
