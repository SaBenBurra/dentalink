import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/generated/app_localizations.dart';

/// Bir [DateTime] değerini göreli zaman metni olarak gösteren widget.
///
/// Örneğin "5 dk önce", "2 saat önce", "3 gün önce" gibi metinler üretir.
/// Metinler aktif dile göre ARB'den gelir.
///
/// Statik [format] metodu, widget dışında da kullanılabilir.
///
/// ```dart
/// RelativeTimeText(
///   dateTime: post.createdAt,
///   prefix: 'Paylaşıldı: ',
/// )
/// ```
class RelativeTimeText extends StatelessWidget {
  /// Yeni bir [RelativeTimeText] oluşturur.
  ///
  /// [dateTime] göreli zamanı hesaplanacak tarih/saattir.
  /// [style] özel metin stili; sağlanmazsa [bodySmall] kullanılır.
  /// [prefix] metin öncesine eklenen isteğe bağlı ön ek.
  const RelativeTimeText({
    super.key,
    required this.dateTime,
    this.style,
    this.prefix,
  });

  /// Göreli zamanı hesaplanacak tarih/saat.
  final DateTime dateTime;

  /// Metin stili. Sağlanmazsa tema'nın [bodySmall] stili kullanılır.
  final TextStyle? style;

  /// Metnin başına eklenen isteğe bağlı ön ek.
  final String? prefix;

  /// Verilen [dateTime] değerini göreli zaman metnine dönüştürür.
  ///
  /// Metinler ARB'den; 30+ gün için ay adı intl ile aktif dilde yazılır.
  static String format(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // < 1 dakika
    if (difference.inMinutes < 1) {
      return l10n.timeJustNow;
    }

    // < 60 dakika
    if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    }

    // < 24 saat
    if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    }

    // < 7 gün
    if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    }

    // < 30 gün
    if (difference.inDays < 30) {
      return l10n.timeWeeksAgo(difference.inDays ~/ 7);
    }

    // 30+ gün — 'dd MMM yyyy' formatı
    return DateFormat('dd MMM yyyy', l10n.localeName).format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final formatted = format(dateTime, l10n);
    final displayText = prefix != null ? '$prefix$formatted' : formatted;

    final effectiveStyle =
        style ??
        textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);

    return Text(displayText, style: effectiveStyle);
  }
}
