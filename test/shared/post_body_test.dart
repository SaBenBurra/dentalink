import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/shared/widgets/post_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('truncateAtWord', () {
    test('sınırın altındaki metin aynen döner', () {
      expect(truncateAtWord('kısa metin', 300), 'kısa metin');
    });

    test('kelime ortasında bölmez, … ekler', () {
      expect(truncateAtWord('kanal tedavisi sonrası', 17), 'kanal tedavisi…');
    });

    test('boşluk çok gerideyse sınırda keser', () {
      expect(truncateAtWord('a ${'b' * 20}', 10), 'a ${'b' * 8}…');
    });

    test('emojiyi ortadan bölmez', () {
      expect(truncateAtWord('🦷🦷🦷', 2), '🦷🦷…');
    });
  });

  testWidgets('Devamını oku her basışta içeriği uzatır, bitince kaybolur', (
    tester,
  ) async {
    final content = List.filled(200, 'kelime').join(' '); // 1399 karakter
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostBody(title: 'Başlık', content: content),
          ),
        ),
      ),
    );

    final body = find.textContaining('kelime');
    String plain() => tester.widget<Text>(body).textSpan!.toPlainText();
    final readMore = find.textRange.ofSubstring('Devamını oku');

    expect(plain(), endsWith('… Devamını oku')); // metnin bittiği yerde
    expect(plain().length, lessThanOrEqualTo(postPreviewChars + 14));
    var previous = plain().length;
    while (plain().endsWith('Devamını oku')) {
      await tester.ensureVisible(body);
      await tester.tapOnText(readMore);
      await tester.pump();
      expect(plain().length, greaterThan(previous));
      previous = plain().length;
    }
    expect(plain(), content);
  });
}
