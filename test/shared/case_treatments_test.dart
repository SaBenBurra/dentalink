import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/case_treatment.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/shared/widgets/case_treatments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('kartta ilk iki tedavi, gerisi "+N" (post sayfasını açar)', (
    tester,
  ) async {
    var more = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CaseTreatmentsRow(
            treatments: [
              for (final t in [
                TreatmentType.tamAgizRehabilitasyonu,
                TreatmentType.implant,
                TreatmentType.sinusLifting,
                TreatmentType.kemikGrefti,
                TreatmentType.kron,
              ])
                CaseTreatment.listed(t),
            ],
            onMore: () => more++,
          ),
        ),
      ),
    );
    expect(find.byType(TreatmentChip), findsNWidgets(2));
    expect(find.text('İmplant cerrahisi'), findsOneWidget);
    expect(find.text('Sinüs lifting'), findsNothing);
    await tester.tap(find.text('+3'));
    expect(more, 1);
    expect(find.bySemanticsLabel('3 tedavi daha'), findsOneWidget);
  });
}
