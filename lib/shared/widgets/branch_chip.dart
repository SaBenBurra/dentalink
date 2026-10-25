import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../data/models/enums.dart';
import '../extensions/dental_branch_ui.dart';

/// Diş hekimliği branşlarını görüntülemek için kullanılan chip widget'ı.
///
/// Her branş için özel bir renk tanımlanmıştır. Seçili olmadığında
/// branş renginin %15 opaklığında arka plan ve branş rengi metin;
/// seçili olduğunda branş rengi arka plan ve beyaz metin kullanır.
///
/// [showIcon] etkinleştirildiğinde metin öncesinde küçük bir renkli
/// nokta (6px) gösterilir.
///
/// ```dart
/// BranchChip(
///   branch: DentalBranch.endodonti,
///   isSelected: true,
///   showIcon: true,
///   onTap: () => print('tapped'),
/// )
/// ```
class BranchChip extends StatelessWidget {
  /// Yeni bir [BranchChip] oluşturur.
  ///
  /// [branch] gösterilecek diş hekimliği branşıdır.
  /// [onTap] chip'e tıklandığında tetiklenir.
  /// [isSelected] seçili durumu belirler, varsayılan olarak `false`.
  /// [showIcon] metin öncesinde renkli nokta göstermeyi kontrol eder.
  const BranchChip({
    super.key,
    required this.branch,
    this.onTap,
    this.isSelected = false,
    this.showIcon = false,
  });

  /// Gösterilecek diş hekimliği branşı.
  final DentalBranch branch;

  /// Chip'e tıklandığında tetiklenen callback.
  final VoidCallback? onTap;

  /// Chip'in seçili olup olmadığını belirler.
  ///
  /// `true` olduğunda branş rengi arka plan ve beyaz metin kullanılır.
  final bool isSelected;

  /// `true` olduğunda metin öncesinde küçük renkli bir nokta gösterir.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final branchColor = branch.color;

    final backgroundColor = isSelected
        ? branchColor
        : branchColor.withValues(alpha: 0.15);

    final foregroundColor = isSelected ? Colors.white : branchColor;

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
                if (showIcon) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: foregroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing6),
                ],
                Text(
                  branch.displayName,
                  style: textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
