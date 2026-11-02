import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';

/// Kartta ilk gösterilen içerik uzunluğu (karakter, ~5 satır).
const int postPreviewChars = 300;

/// [text]'in ilk [limit] karakteri; kesilirse kelime ortasında bölmez, sonuna … ekler.
/// Emoji gibi çok kod birimli karakterleri bölmemek için grapheme bazında sayar.
String truncateAtWord(String text, int limit) {
  final chars = text.characters;
  if (chars.length <= limit) return text;
  var cut = chars.take(limit).toString();
  final space = cut.lastIndexOf(RegExp(r'\s'));
  // Çok uzun tek kelimede boşluğa dönmek metni fazla kısaltır.
  if (space > cut.length * 0.6) cut = cut.substring(0, space);
  return '${cut.trimRight()}…';
}

/// Post kartlarında başlık ve içerik alanlarını render eden
/// ortak widget. `CaseCard` ve `QuestionCard` bu widget'ı paylaşır.
/// Feed'de uzun içerik kısaltılır; "Devamını oku" ayrı bir dokunma hedefi değil,
/// karta dokununca açılan post sayfası ([expanded]) metnin tamamını gösterir.
class PostBody extends StatelessWidget {
  const PostBody({
    super.key,
    required this.title,
    required this.content,
    this.expanded = false,
  });

  final String title;
  final String content;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shown = expanded
        ? content
        : truncateAtWord(content, postPreviewChars);
    final isTruncated = shown != content;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: expanded ? null : 2,
            overflow: expanded ? null : TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text.rich(
            TextSpan(
              text: shown,
              children: [
                if (isTruncated)
                  TextSpan(
                    text: ' ${AppLocalizations.of(context)!.readMore}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),
        ],
      ),
    );
  }
}
