import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/features/post/widgets/tag_input.dart';
import 'package:dentlink/features/post/widgets/treatment_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('"Diğer" adı etiket biçimine çevrilir', () {
    expect(TreatmentSelector.otherTag('  Kök Amputasyonu '), 'kök-amputasyonu');
    expect(TreatmentSelector.otherTag('#Hemiseksiyon'), 'hemiseksiyon');
    expect(TreatmentSelector.otherTag('   '), isEmpty);
  });

  group('widget', () {
    TreatmentType? selected;
    String? other;

    Future<void> pump(WidgetTester tester) async {
      selected = null;
      other = null;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TreatmentSelector(
              branch: DentalBranch.endodonti,
              selected: selected,
              other: other,
              suggest: (q) async => ['kanal-tedavisi', 'hemiseksiyon'],
              onSelected: (t) => setState(() {
                selected = t;
                other = null;
              }),
              onOtherChanged: (v) => setState(() {
                selected = null;
                other = v;
              }),
            ),
          ),
        ),
      ));
    }

    testWidgets('yalnızca branşın türleri ve "Diğer" listelenir', (tester) async {
      await pump(tester);
      expect(find.byType(ChoiceChip),
          findsNWidgets(TreatmentType.forBranch(DentalBranch.endodonti).length + 1));
      expect(find.text('Diğer'), findsOneWidget);
      expect(find.text('Braket'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('"Diğer"de ad yazılır; listede olan öneri o türü seçer', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Diğer'));
      await tester.pump();
      expect(other, '');

      await tester.enterText(find.byType(TextField), 'kan');
      await tester.pump(TagInput.suggestDebounce);
      await tester.pump();
      expect(other, 'kan');
      expect(find.text('Kanal tedavisi'), findsNWidgets(2), reason: 'çip + öneri');
      expect(find.text('listede var'), findsOneWidget);
      expect(find.text('#hemiseksiyon'), findsOneWidget);

      await tester.tap(find.text('listede var'));
      await tester.pump();
      expect(selected, TreatmentType.kanalTedavisi);
      expect(other, isNull);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('listede olmayan öneri "Diğer" adı olur', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Diğer'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'hemi');
      await tester.pump(TagInput.suggestDebounce);
      await tester.pump();
      await tester.tap(find.text('#hemiseksiyon'));
      await tester.pump();
      expect(other, 'hemiseksiyon');
      expect(selected, isNull);
    });
  });
}
