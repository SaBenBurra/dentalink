import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:go_router/go_router.dart';
import 'package:dentlink/features/post/screens/post_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/app_flow.dart';
import '../integration_test/fake_repositories.dart';

void main() {
  testWidgets('feed: dokunma alanı ≥48dp, butonların etiketi var (UX-13/14)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDentLink(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('yorumlar penceresi: dokunma alanı ve etiketler (UX-13/14)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDentLink(tester);
    await tester.tap(find.byIcon(CupertinoIcons.chat_bubble).first);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('tek post sayfası: dokunma alanı ve etiketler (UX-13/14)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDentLink(tester);
    // Feed'den gidilmiyor (arama/profil/bildirim/deep link'ten açılır).
    GoRouter.of(
      tester.element(find.text(seedCase.title)),
    ).push('/post/${seedCase.id}');
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
