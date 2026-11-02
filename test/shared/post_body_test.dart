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

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  final content = List.filled(200, 'kelime').join(' '); // 1399 karakter
  String plain(WidgetTester tester) => tester
      .widget<Text>(find.textContaining('kelime'))
      .textSpan!
      .toPlainText();

  testWidgets('kartta kısaltılır, "Devamını oku" yalnızca işaret', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(PostBody(title: 'Başlık', content: content)));
    expect(plain(tester), endsWith('… Devamını oku'));
    expect(plain(tester).length, lessThanOrEqualTo(postPreviewChars + 14));
  });

  testWidgets('post sayfasında metnin tamamı gösterilir', (tester) async {
    await tester.pumpWidget(
      wrap(PostBody(title: 'Başlık', content: content, expanded: true)),
    );
    expect(plain(tester), content);
  });
}
