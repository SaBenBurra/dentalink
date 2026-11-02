import 'package:dentlink/features/search/screens/search_screen.dart';
import 'package:dentlink/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';

void main() {
  testWidgets('karttaki etikete dokununca Keşfet o etiketle açılır', (
    tester,
  ) async {
    await pumpDentLink(tester);
    await tester.tap(find.text('#Kalsifiye_Kanal'));
    await tester.pumpAndSettle();

    final search = find.byType(SearchScreen);
    expect(search, findsOneWidget);
    final field = tester.widget<TextField>(
      find.descendant(of: search, matching: find.byType(TextField)).first,
    );
    expect(field.controller!.text, '#Kalsifiye_Kanal');
    expect(
      ProviderScope.containerOf(
        tester.element(search),
      ).read(searchProvider).query,
      '#Kalsifiye_Kanal',
    );
  });
}
