import 'package:flutter/material.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

/// Gönderi formlarında bölüm başlığı: renkli küçük ikon + kalın başlık.
class FormSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;

  const FormSectionLabel({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacing6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconSmall,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Gönderi formlarında bölümler arası ayraç: geniş boşluk + ince çizgi.
class FormSectionDivider extends StatelessWidget {
  const FormSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(
          alpha: 0.5,
        ),
      ),
    );
  }
}
