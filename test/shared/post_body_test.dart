import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/tag_model.dart';
import 'package:dentigo/shared/widgets/post_body.dart';
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

  testWidgets('kartta kısaltılır, sonda "Devamını oku" var', (tester) async {
    await tester.pumpWidget(wrap(PostBody(title: 'Başlık', content: content)));
    expect(plain(tester), endsWith('… Devamını oku'));
    expect(plain(tester).length, lessThanOrEqualTo(postPreviewChars + 14));
  });

  testWidgets('etiketler kartta yok, post sayfasında alt satırda', (
    tester,
  ) async {
    Widget body({required bool expanded}) => wrap(
      PostBody(
        title: 'Başlık',
        content: content,
        tags: const [TagModel(id: '1', name: 'Kalsifiye Kanal', slug: 'k')],
        expanded: expanded,
      ),
    );
    await tester.pumpWidget(body(expanded: false));
    expect(find.text('#Kalsifiye_Kanal'), findsNothing);
    await tester.pumpWidget(body(expanded: true));
    expect(find.text('#Kalsifiye_Kanal'), findsOneWidget);
    expect(plain(tester), contains('$content\n'));
  });

  testWidgets(
    '"Devamını oku" metni kartın içinde açar, post sayfasına gitmez',
    (tester) async {
      var cardTaps = 0;
      await tester.pumpWidget(
        wrap(
          InkWell(
            onTap: () => cardTaps++,
            child: PostBody(title: 'Başlık', content: content),
          ),
        ),
      );
      await tester.tapOnText(find.textRange.ofSubstring('Devamını oku'));
      await tester.pump();
      expect(plain(tester), content);
      expect(cardTaps, 0);

      // Liste aynı State'i başka posta verirse kısaltma geri gelir.
      await tester.pumpWidget(
        wrap(
          InkWell(
            onTap: () => cardTaps++,
            child: PostBody(title: 'Başlık', content: '$content x'),
          ),
        ),
      );
      expect(plain(tester), endsWith('… Devamını oku'));
    },
  );

  testWidgets('post sayfasında metnin tamamı gösterilir', (tester) async {
    await tester.pumpWidget(
      wrap(PostBody(title: 'Başlık', content: content, expanded: true)),
    );
    expect(plain(tester), content);
  });
}
