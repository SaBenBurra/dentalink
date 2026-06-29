import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// İkon ve sayaç görüntüleyen kompakt istatistik widget'ı.
///
/// Beğeni, yorum, paylaşım gibi etkileşim sayaçlarını göstermek
/// için kullanılır. Büyük sayıları otomatik olarak kısaltır
/// (ör. 1200 → "1.2K", 1500000 → "1.5M").
///
/// [isActive] durumuna göre renk değişir: aktif olduğunda
/// [activeColor] (veya tema'nın primary rengi), aktif olmadığında
/// [onSurfaceVariant] kullanılır.
///
/// ```dart
/// StatCount(
///   icon: Icons.favorite_rounded,
///   count: 1234,
///   isActive: true,
///   activeColor: AppColors.like,
///   onTap: () => print('liked'),
/// )
/// ```
class StatCount extends StatelessWidget {
  /// Yeni bir [StatCount] oluşturur.
  ///
  /// [icon] gösterilecek ikon verisidir.
  /// [count] gösterilecek sayı değeridir.
  /// [label] isteğe bağlı olarak sayının yanında/altında gösterilir.
  /// [onTap] tıklama callback'idir.
  /// [iconColor] ikonun özel rengi (aktif değilken).
  /// [iconSize] ikon boyutu, varsayılan [AppDimensions.iconMedium] (20).
  /// [isActive] aktif durumu belirler, varsayılan `false`.
  /// [activeColor] aktif durumdaki renk; sağlanmazsa primary kullanılır.
  const StatCount({
    super.key,
    required this.icon,
    required this.count,
    this.label,
    this.onTap,
    this.iconColor,
    this.iconSize = AppDimensions.iconMedium,
    this.isActive = false,
    this.activeColor,
  });

  /// Gösterilecek ikon.
  final IconData icon;

  /// Gösterilecek sayı değeri.
  final int count;

  /// İsteğe bağlı etiket metni (ör. "beğeni", "yorum").
  final String? label;

  /// Tıklama callback'i. Sağlanırsa InkWell ile sarılır.
  final VoidCallback? onTap;

  /// İkon rengi (aktif değilken). Sağlanmazsa [onSurfaceVariant] kullanılır.
  final Color? iconColor;

  /// İkon boyutu. Varsayılan: [AppDimensions.iconMedium] (20px).
  final double iconSize;

  /// Aktif durum (ör. beğenilmiş, kaydedilmiş).
  ///
  /// `true` olduğunda [activeColor] veya tema primary rengi kullanılır.
  final bool isActive;

  /// Aktif durumdaki renk. Sağlanmazsa tema'nın primary rengi kullanılır.
  final Color? activeColor;

  /// Büyük sayıları kısaltılmış formata dönüştürür.
  ///
  /// - 0–999: olduğu gibi gösterilir
  /// - 1.000–999.999: "1.2K" formatında
  /// - 1.000.000+: "1.2M" formatında
  static String formatCount(int count) {
    if (count >= 1000000) {
      final value = count / 1000000;
      // Tam sayı ise ondalık gösterme
      return value == value.roundToDouble()
          ? '${value.round()}M'
          : '${value.toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return value == value.roundToDouble()
          ? '${value.round()}K'
          : '${value.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final effectiveColor = isActive
        ? (activeColor ?? colorScheme.primary)
        : (iconColor ?? colorScheme.onSurfaceVariant);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: effectiveColor),
        const SizedBox(width: AppDimensions.spacing4),
        Text(
          formatCount(count),
          style: textTheme.labelMedium?.copyWith(color: effectiveColor),
        ),
        if (label != null) ...[
          const SizedBox(width: AppDimensions.spacing2),
          Text(
            label!,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: content,
      );
    }

    return content;
  }
}
