import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/tag_model.dart';
import '../../providers/search_provider.dart';

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
/// Feed'de uzun içerik kısaltılır; "Devamını oku" metni kartın içinde açar, karta
/// dokunmak ise post sayfasını ([expanded]) açar.
class PostBody extends StatefulWidget {
  const PostBody({
    super.key,
    required this.title,
    required this.content,
    this.tags = const [],
    this.expanded = false,
  });

  final String title;
  final String content;

  /// Yalnızca post sayfasında ([expanded]), metnin bir alt satırında, metnin
  /// parçası gibi gösterilir. Dokununca Keşfet o etiketle açılır.
  final List<TagModel> tags;

  final bool expanded;

  @override
  State<PostBody> createState() => _PostBodyState();
}

class _PostBodyState extends State<PostBody> {
  var _showAll = false;
  late final _readMoreTap = TapGestureRecognizer()
    ..onTap = () => setState(() => _showAll = true);

  @override
  void didUpdateWidget(PostBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Liste aynı State'i başka bir posta verebilir.
    if (oldWidget.content != widget.content) _showAll = false;
  }

  @override
  void dispose() {
    _readMoreTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PostBody(:title, :content, :tags, :expanded) = widget;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shown = expanded || _showAll
        ? content
        : truncateAtWord(content, postPreviewChars);
    final isTruncated = shown != content;
    final shownTags = expanded ? tags : const <TagModel>[];
    final bodyStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.85),
      height: 1.5,
    );

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
                    recognizer: _readMoreTap,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (shownTags.isNotEmpty && shown.isNotEmpty)
                  const TextSpan(text: '\n'),
                for (final tag in shownTags) ...[
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Semantics(
                      link: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go(
                          Uri(
                            path: '/search',
                            queryParameters: {'tag': tag.name},
                          ).toString(),
                        ),
                        child: Text(
                          hashtag(tag.name),
                          style: bodyStyle?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            style: bodyStyle,
          ),
          const SizedBox(height: AppDimensions.spacing12),
        ],
      ),
    );
  }
}
