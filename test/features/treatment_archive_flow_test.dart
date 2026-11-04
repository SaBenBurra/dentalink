import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/features/search/screens/search_screen.dart';
import 'package:dentlink/features/treatments/screens/treatment_archive_screen.dart';
import 'package:dentlink/providers/search_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';

void main() {
  testWidgets(
    'ana sayfada tedavi yok; post sayfasındaki çip → arşiv → branş linki Keşfet\'i açar',
    (tester) async {
      await pumpDentLink(tester);

      // Tedavi etiketi serbest etiket satırında tekrar görünmez.
      expect(find.text('#kanal-tedavisi'), findsNothing);
      expect(find.text('Kanal tedavisi'), findsNothing);

      await tester.tap(find.text('Alt molar kanal tedavisi'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kanal tedavisi').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kanal tedavisi').first);
      await tester.pumpAndSettle();

      expect(find.byType(TreatmentArchiveScreen), findsOneWidget);
      expect(find.text('1 vaka'), findsOneWidget);
      expect(find.text('Alt molar kanal tedavisi'), findsOneWidget);

      await tester.tap(find.text('Endodonti'));
      await tester.pumpAndSettle();
      final search = find.byType(SearchScreen);
      expect(search, findsOneWidget);
      final state = ProviderScope.containerOf(
        tester.element(search),
      ).read(searchProvider);
      expect(state.branch, DentalBranch.endodonti);
      expect(state.query, isEmpty);
    },
  );
}
