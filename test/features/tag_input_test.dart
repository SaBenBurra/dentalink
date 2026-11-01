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
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TagInput(onTagsChanged: (t) => emitted = t)),
        ),
      );
    }

    testWidgets('onaylanmamış etiket de üst bileşene iletilir', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), '#Kanal');
      expect(emitted, ['kanal']);
    });

    testWidgets('yapıştırılan metin bölünür, en fazla 5 etiket', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'a,b c d e f g');
      await tester.pump();

      expect(emitted, ['a', 'b', 'c', 'd', 'e']);
      expect(
        find.byType(TextField),
        findsNothing,
        reason: 'limit dolunca alan gizlenir',
      );
    });
  });

  group('öneri', () {
    late List<String> emitted;
    late List<String> queries;

    Future<void> pump(WidgetTester tester) async {
      emitted = [];
      queries = [];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TagInput(
              initialTags: const ['implant-üstü-protez'],
              onTagsChanged: (t) => emitted = t,
              suggest: (q) async {
                queries.add(q);
                return ['implant', 'implant-üstü-protez'];
              },
            ),
          ),
        ),
      );
    }

    testWidgets('2 karakterden önce istek yok, sonra debounce ile tek istek', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'i');
      await tester.pump(TagInput.suggestDebounce);
      expect(queries, isEmpty);

      await tester.enterText(find.byType(TextField), 'İm');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'İmp');
      await tester.pump(TagInput.suggestDebounce);
      await tester.pump();

      expect(queries, [
        'imp',
      ], reason: 'normalize edilmiş son sorgu, ara harf istek atmaz');
      expect(find.text('#implant'), findsOneWidget);
      expect(
        find.text('#implant-üstü-protez'),
        findsOneWidget,
        reason: 'zaten ekli olan çip',
      );
      expect(
        find.byType(ListTile),
        findsOneWidget,
        reason: 'ekli etiket önerilmez',
      );
    });

    testWidgets('öneriye dokununca etiket eklenir, alan temizlenir', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'imp');
      await tester.pump(TagInput.suggestDebounce);
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, '#implant'));
      await tester.pump();

      expect(emitted, ['implant-üstü-protez', 'implant']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('serbest etiket hâlâ eklenebilir', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'kendi-etiketim ');
      await tester.pump(TagInput.suggestDebounce);
      expect(emitted, ['implant-üstü-protez', 'kendi-etiketim']);
    });
  });

  group('sabit etiket (tedavi türü)', () {
    late List<String> emitted;

    Widget app(String? locked, {List<String> initial = const []}) =>
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TagInput(
              initialTags: initial,
              lockedTag: locked,
              onTagsChanged: (t) => emitted = t,
            ),
          ),
        );

    testWidgets('silinemez, sınıra dahil, iletilmez, tekrar eklenmez', (
      tester,
    ) async {
      emitted = [];
      await tester.pumpWidget(app('kanal-tedavisi'));

      expect(find.text('#kanal-tedavisi'), findsOneWidget);
      expect(find.byType(InputChip), findsNothing, reason: 'silme düğmesi yok');
      expect(find.text('1/5'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'kanal-tedavisi a b c d e ',
      );
      await tester.pump();
      expect(emitted, [
        'a',
        'b',
        'c',
        'd',
      ], reason: 'sabit etiket bir yer kaplar');
      expect(find.text('5/5'), findsOneWidget);
    });

    testWidgets(
      'sabit etiket gelince fazla etiket düşer, eski sabit etiket kalkar',
      (tester) async {
        emitted = [];
        await tester.pumpWidget(
          app('kron', initial: ['kron', 'a', 'b', 'c', 'd']),
        );
        expect(
          find.text('5/5'),
          findsOneWidget,
          reason: 'başlangıçtaki sabit etiket tekrar sayılmaz',
        );

        await tester.pumpWidget(
          app('köprü', initial: ['kron', 'a', 'b', 'c', 'd']),
        );
        await tester.pump();
        expect(emitted, [
          'a',
          'b',
          'c',
          'd',
        ], reason: 'eski tedavinin etiketi gider');
      },
    );

    testWidgets('5 serbest etiketli posta tedavi seçilince sondaki düşer', (
      tester,
    ) async {
      emitted = [];
      const initial = ['a', 'b', 'c', 'd', 'e'];
      await tester.pumpWidget(app(null, initial: initial));
      await tester.pumpWidget(app('kron', initial: initial));
      await tester.pump();
      expect(emitted, ['a', 'b', 'c', 'd']);
      expect(find.text('5/5'), findsOneWidget);
    });
  });
}
