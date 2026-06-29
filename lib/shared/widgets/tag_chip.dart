import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Gönderi etiketlerini görüntülemek için kullanılan chip widget'ı.
///
/// Material 3 renk şemasına uygun şekilde tasarlanmıştır.
/// Seçili olmadığında [surfaceContainerHighest] arka plan ve
/// [onSurfaceVariant] metin rengi; seçili olduğunda [primaryContainer]
/// arka plan ve [onPrimaryContainer] metin rengi kullanır.
///
/// [onDelete] sağlandığında sağ tarafta küçük bir kapatma ikonu gösterir.
/// Renk geçişleri [AnimatedContainer] ile yumuşak bir şekilde animasyonlanır.
///
/// ```dart
/// TagChip(
///   label: 'Endodonti',
///   isSelected: true,
///   onTap: () => print('tapped'),
///   onDelete: () => print('deleted'),
/// )
/// ```
class TagChip extends StatelessWidget {
  /// Yeni bir [TagChip] oluşturur.
  ///
  /// [label] görüntülenecek etiket metnidir.
  /// [onTap] chip'e tıklandığında tetiklenir.
  /// [onDelete] sağlanırsa sağ tarafta kapatma ikonu gösterir.
  /// [isSelected] seçili durumu belirler, varsayılan olarak `false`.
  const TagChip({
    super.key,
    required this.label,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
  });

  /// Chip üzerinde görüntülenecek etiket metni.
  final String label;

  /// Chip'e tıklandığında tetiklenen callback.
  final VoidCallback? onTap;

  /// Sağlanırsa kapatma ikonu gösterilir ve tıklandığında tetiklenir.
  final VoidCallback? onDelete;

  /// Chip'in seçili olup olmadığını belirler.
  ///
  /// `true` olduğunda [primaryContainer] arka planı kullanılır.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    final foregroundColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: AppDimensions.animFast,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: AppDimensions.spacing4),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
