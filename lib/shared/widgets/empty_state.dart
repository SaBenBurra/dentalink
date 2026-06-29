import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

/// Boş durum bileşeni — liste veya akışta veri olmadığında gösterilir.
///
/// Büyük ikon, başlık, isteğe bağlı alt başlık ve aksiyon butonu içerir.
/// Tüm renkler temadan alınır, aydınlık ve karanlık tema ile uyumludur.
///
/// ```dart
/// DentLinkEmptyState(
///   icon: Icons.article_outlined,
///   title: 'Henüz gönderi yok',
///   subtitle: 'İlk gönderiyi sen paylaş!',
///   actionLabel: 'Gönderi Oluştur',
///   onAction: () => context.push('/feed/create'),
/// )
/// ```
class DentLinkEmptyState extends StatelessWidget {
  const DentLinkEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  });

  /// Gösterilecek ikon. Varsayılan: [Icons.inbox_outlined].
  final IconData icon;

  /// Ana başlık metni.
  final String title;

  /// İsteğe bağlı açıklama metni.
  final String? subtitle;

  /// Aksiyon butonunun etiketi. Null ise buton gösterilmez.
  final String? actionLabel;

  /// Aksiyon butonuna basıldığında çağrılacak callback.
  final VoidCallback? onAction;

  /// İkon boyutu (piksel). Varsayılan: 64.
  final double iconSize;

  /// İkon rengi. Null ise temanın `onSurfaceVariant` rengi kullanılır.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final effectiveIconColor = iconColor ?? colorScheme.onSurfaceVariant;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── İkon ──
              Icon(icon, size: iconSize, color: effectiveIconColor),
              const SizedBox(height: AppDimensions.spacing16),

              // ── Başlık ──
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              // ── Alt başlık ──
              if (subtitle != null) ...[
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // ── Aksiyon butonu ──
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppDimensions.spacing24),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
