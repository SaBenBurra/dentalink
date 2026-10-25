import 'package:flutter_test/flutter_test.dart';

import '../integration_test/app_flow.dart';
import '../integration_test/fake_repositories.dart';

void main() {
  testWidgets('feed: dokunma alanı ≥48dp, butonların etiketi var (UX-13/14)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDentLink(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('vaka detayı: dokunma alanı ve etiketler (UX-13/14)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDentLink(tester);
    await tester.tap(find.text(seedCase.title));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
