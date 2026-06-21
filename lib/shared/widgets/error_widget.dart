import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';

/// Hata durumu bileşeni — yeniden deneme desteği ile.
///
/// Veri çekme başarısız olduğunda veya beklenmeyen bir hata oluştuğunda
/// kullanıcıya ikon, mesaj ve isteğe bağlı yeniden deneme butonu gösterir.
///
/// Flutter'ın yerleşik [ErrorWidget] sınıfı ile isim çakışmasını önlemek
/// için `DentLinkErrorWidget` olarak adlandırılmıştır.
///
/// ```dart
/// DentLinkErrorWidget(
///   message: 'Gönderiler yüklenemedi.',
///   onRetry: () => ref.invalidate(feedProvider),
/// )
/// ```
class DentLinkErrorWidget extends StatelessWidget {
  const DentLinkErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.iconColor,
  });

  /// Görüntülenecek hata mesajı.
  /// Null ise [AppLocalizations.unknownError] kullanılır.
  final String? message;

  /// Yeniden deneme butonuna basıldığında çağrılacak callback.
  /// Null ise buton gösterilmez.
  final VoidCallback? onRetry;

  /// Hata ikonu. Varsayılan: [Icons.error_outline_rounded].
  final IconData icon;

  /// İkon rengi. Null ise temanın `error` rengi kullanılır.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final effectiveIconColor = iconColor ?? colorScheme.error;
    final displayMessage = message ?? l10n.unknownError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Hata ikonu ──
            Icon(
              icon,
              size: AppDimensions.spacing48,
              color: effectiveIconColor,
            ),
            const SizedBox(height: AppDimensions.spacing16),

            // ── Hata mesajı ──
            Text(
              displayMessage,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Yeniden dene butonu ──
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
