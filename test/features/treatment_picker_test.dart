import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/case_treatment.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/features/post/widgets/tag_input.dart';
import 'package:dentigo/features/post/widgets/treatment_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const remote = CaseTreatment(
    slug: 'hemiseksiyon',
    name: 'hemiseksiyon',
    branch: DentalBranch.endodonti,
    caseCount: 3,
  );
  CaseTreatment? picked;

  Future<void> pump(WidgetTester tester, {Set<String> taken = const {}}) async {
    picked = null;
    // Pencere tembel liste; branşın bütün satırları ekrana sığsın.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await showTreatmentPicker(
                context,
                taken: taken,
                search: (q) async => q.startsWith('hemi') ? [remote] : [],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(TagInput.suggestDebounce);
    await tester.pumpAndSettle();
  }

  testWidgets('açılışta liste yok; branş seçilince yalnızca onun tedavileri', (
    tester,
  ) async {
    await pump(tester, taken: {'kanal-tedavisi'});
    expect(find.byType(ListTile), findsNothing);

    await tester.tap(find.text('Endo'));
    await tester.pumpAndSettle();
    expect(
      find.byType(ListTile),
      findsNWidgets(TreatmentType.forBranch(DentalBranch.endodonti).length + 1),
      reason: 'tedaviler + "Listede yok mu? Ekle"',
    );
    expect(find.text('Braket'), findsNothing);
    // Seçili olan gri ve seçilemez.
    await tester.tap(find.text('Kanal tedavisi'));
    await tester.pumpAndSettle();
    expect(picked, isNull);

    await tester.tap(find.text('Kanal tedavisi yenileme'));
    await tester.pumpAndSettle();
    expect(picked, CaseTreatment.listed(TreatmentType.yenidenKanalTedavisi));
  });

  testWidgets('arama tüm branşlarda; sunucu sonucu da listelenir', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'kron');
    expect(find.text('Kron'), findsOneWidget);
    expect(find.text('Kron boyu uzatma'), findsOneWidget, reason: 'Perio');
    expect(find.textContaining('ekle'), findsNothing, reason: 'tam eşleşme');

    await type(tester, 'hemiseksiyon');
    expect(find.text('Hemiseksiyon'), findsOneWidget);
    await tester.tap(find.text('Hemiseksiyon'));
    await tester.pumpAndSettle();
    expect(picked, remote);
  });

  testWidgets('listede olmayan tedavi: "ekle" → branş sorulur', (tester) async {
    await pump(tester);
    await type(tester, 'Zirkonya İnley');
    await tester.tap(find.text('"Zirkonya inley" ekle'));
    await tester.pumpAndSettle();
    expect(find.text('"Zirkonya inley" hangi branşa ait?'), findsOneWidget);

    await tester.tap(find.text('Protez'));
    await tester.pumpAndSettle();
    expect(picked?.slug, 'zirkonya-inley');
    expect(picked?.name, 'zirkonya-inley');
    expect(picked?.branch, DentalBranch.protetikDisTedavisi);
  });

  testWidgets('branşta "Listede yok mu? Ekle": branş sorulmaz', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Perio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listede yok mu? Ekle'));
    await tester.pumpAndSettle();
    await type(tester, 'lazer');
    await tester.tap(find.text('"Lazer" ekle'));
    await tester.pumpAndSettle();
    expect(picked?.branch, DentalBranch.periodontoloji);
  });
}
