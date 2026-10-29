import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/shared/extensions/post_type_l10n.dart';
import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';

class PostBadge extends StatelessWidget {
  const PostBadge({super.key, required this.postType, this.label});

  final PostType postType;

  /// Verilirse tür etiketi yerine yazılır (ör. profilde unvan); renkler türden gelir.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Soru: marka teal; vaka: paletin "Professional Blue" ailesi.
    final (
      Color background,
      Color border,
      Color foreground,
    ) = switch (postType) {
      PostType.casePost =>
        isDark
            ? (
                AppColors.secondaryLight.withValues(alpha: 0.2),
                AppColors.secondaryLight.withValues(alpha: 0.4),
                AppColors.secondaryContainer,
              )
            : (
                AppColors.secondaryContainer.withValues(alpha: 0.7),
                AppColors.secondaryLight.withValues(alpha: 0.4),
                AppColors.secondaryDark,
              ),
      PostType.question =>
        isDark
            ? (
                colorScheme.primaryContainer.withValues(alpha: 0.2),
                colorScheme.primary.withValues(alpha: 0.3),
                colorScheme.primaryContainer,
              )
            : (
                AppColors.primaryContainer.withValues(alpha: 0.4),
                AppColors.primaryContainer,
                AppColors.primaryDark,
              ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing8,
        vertical: AppDimensions.spacing2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label ?? postType.getBadgeLabel(context),
        style: textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
