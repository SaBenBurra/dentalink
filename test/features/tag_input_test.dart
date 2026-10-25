import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/post/widgets/tag_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalize # ve boşluğu atar, Türkçe küçültür', () {
    expect(TagInput.normalize('  #İmplant '), 'implant');
    expect(TagInput.normalize('KIRIK'), 'kırık');
  });

  group('widget', () {
    late List<String> emitted;

    Future<void> pump(WidgetTester tester) async {
      emitted = [];
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TagInput(onTagsChanged: (t) => emitted = t)),
      ));
    }

    testWidgets('onaylanmamış etiket de üst bileşene iletilir', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), '#Kanal');
      expect(emitted, ['kanal']);
    });

    testWidgets('yapıştırılan metin bölünür, en fazla 5 etiket', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'a,b c d e f g');
      await tester.pump();

      expect(emitted, ['a', 'b', 'c', 'd', 'e']);
      expect(find.byType(TextField), findsNothing, reason: 'limit dolunca alan gizlenir');
    });
  });
}
