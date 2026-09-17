import 'package:dentlink/data/models/tag_model.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/tag_chip.dart';

/// Post kartlarında başlık, içerik ve etiket alanlarını render eden
/// ortak widget. `CaseCard` ve `QuestionCard` bu widget'ı paylaşır;
/// iki kart arasındaki tek fark `contentMaxLines` değeridir.
class PostBody extends StatelessWidget {
  const PostBody({
    super.key,
    required this.title,
    required this.content,
    required this.tags,
    required this.contentMaxLines,
    this.onTagTap, // TODO: Etikete tıklanınca o etiketle filtrelenmiş arama (Faz 4.3)
  });

  final String title;
  final String content;
  final List<TagModel> tags;
  final int contentMaxLines;
  final ValueChanged<TagModel>? onTagTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.5,
            ),
            maxLines: contentMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          if (tags.isNotEmpty) ...[
            Wrap(
              spacing: AppDimensions.spacing6,
              runSpacing: AppDimensions.spacing6,
              children: tags
                  .map(
                    (tag) => TagChip(
                      label: '#${tag.name}',
                      onTap: () => onTagTap?.call(tag),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
        ],
      ),
    );
  }
}
