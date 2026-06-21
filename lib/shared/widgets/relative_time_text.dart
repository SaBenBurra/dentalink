import 'package:flutter/material.dart';

import '../../core/l10n/generated/app_localizations.dart';

/// Bir [DateTime] değerini göreli zaman metni olarak gösteren widget.
///
/// Örneğin "5 dk önce", "2 saat önce", "3 gün önce" gibi metinler üretir.
/// Türkçe ve İngilizce dil desteği sunar ve `intl` paketine bağımlı
/// olmadan tarih formatlama yapar.
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

  /// Türkçe ay isimleri.
  static const List<String> _monthNamesTr = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  /// İngilizce ay isimleri.
  static const List<String> _monthNamesEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Verilen [dateTime] değerini göreli zaman metnine dönüştürür.
  ///
  /// [l10n] yerelleştirme nesnesi dil tespiti için kullanılır.
  /// ARB dosyalarında bu metinler bulunmadığından, locale kontrolüyle
  /// satır içi ele alınır.
  static String format(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final isTurkish = l10n.localeName.startsWith('tr');

    // < 1 dakika
    if (difference.inMinutes < 1) {
      return isTurkish ? 'Az önce' : 'Just now';
    }

    // < 60 dakika
    if (difference.inMinutes < 60) {
      final n = difference.inMinutes;
      return isTurkish ? '$n dk önce' : '$n min ago';
    }

    // < 24 saat
    if (difference.inHours < 24) {
      final n = difference.inHours;
      return isTurkish ? '$n saat önce' : '${n}h ago';
    }

    // < 7 gün
    if (difference.inDays < 7) {
      final n = difference.inDays;
      return isTurkish ? '$n gün önce' : '${n}d ago';
    }

    // < 30 gün
    if (difference.inDays < 30) {
      final n = difference.inDays ~/ 7;
      return isTurkish ? '$n hafta önce' : '${n}w ago';
    }

    // 30+ gün — 'dd MMM yyyy' formatı
    final day = dateTime.day.toString().padLeft(2, '0');
    final monthNames = isTurkish ? _monthNamesTr : _monthNamesEn;
    final month = monthNames[dateTime.month - 1];
    final year = dateTime.year;

    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final formatted = format(dateTime, l10n);
    final displayText = prefix != null ? '$prefix$formatted' : formatted;

    final effectiveStyle = style ??
        textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );

    return Text(
      displayText,
      style: effectiveStyle,
    );
  }
}
