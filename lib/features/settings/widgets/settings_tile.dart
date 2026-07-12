import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Ayarlar sayfasındaki tek bir liste elemanı.
/// Standart tıklanabilir tile veya Switch (toggle) tipinde olabilir.
class SettingsTile extends StatelessWidget {
  /// Standart tıklanabilir ayar elemanı
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  }) : isToggle = false,
       toggleValue = false,
       onToggle = null;

  /// Switch barındıran ayar elemanı (Örn: Bildirimleri aç/kapat)
  const SettingsTile.toggle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required bool value,
    required ValueChanged<bool> this.onToggle,
    this.enabled = true,
  }) : isToggle = true,
       toggleValue = value,
       onTap = null;

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  // Toggle özellikleri
  final bool isToggle;
  final bool toggleValue;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);
    final iconColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.38);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? (isToggle ? () => onToggle?.call(!toggleValue) : onTap)
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing12,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconMedium,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: enabled ? 1.0 : 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              if (isToggle)
                Switch(
                  value: toggleValue,
                  onChanged: enabled ? onToggle : null,
                  activeTrackColor: const Color(0xFF13B9A5),
                )
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
