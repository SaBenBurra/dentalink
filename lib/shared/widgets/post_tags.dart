import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../data/models/tag_model.dart';
import '../../providers/search_provider.dart';

/// Kartta içeriğin altındaki küçük etiketler; dokununca Keşfet o etiketle açılır.
/// Görünen chip küçük, dokunma alanı 48dp. Tek satır, sığmazsa yana kayar.
class PostTags extends StatelessWidget {
  const PostTags({super.key, required this.tags});

  final List<TagModel> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextButton.styleFrom(
      minimumSize: const Size(0, 26),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing8),
      tapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.compact,
      backgroundColor: colorScheme.surfaceContainerHighest,
      foregroundColor: colorScheme.onSurfaceVariant,
      textStyle: Theme.of(context).textTheme.labelSmall,
      shape: const StadiumBorder(),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
      child: Row(
        spacing: AppDimensions.spacing6,
        children: [
          for (final tag in tags)
            TextButton(
              style: style,
              onPressed: () => context.go(
                Uri(
                  path: '/search',
                  queryParameters: {'tag': tag.name},
                ).toString(),
              ),
              child: Text(hashtag(tag.name)),
            ),
        ],
      ),
    );
  }
}
