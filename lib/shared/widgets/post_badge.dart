import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/shared/extensions/post_type_l10n.dart';
import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';

class PostBadge extends StatelessWidget {
  const PostBadge({super.key, required this.postType});

  final PostType postType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing10,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
            : AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.3)
              : AppColors.primaryContainer,
          width: 1,
        ),
      ),
      child: Text(
        '${postType.getBadgeLabel(context)} ${postType.emoji}',
        style: textTheme.labelSmall?.copyWith(
          color: isDark ? colorScheme.primaryContainer : AppColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
