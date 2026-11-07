import 'package:dentigo/core/router/app_router.dart';
import 'package:dentigo/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';

void main() {
  // Sekme içinde açılan listeler: son öğe yüzen alt menünün altında kalmaz.
  for (final location in ['/notifications', '/network/me?tab=0']) {
    testWidgets('$location listesinin sonu barın üstünde', (tester) async {
      await pumpDentigo(tester);
      pushDetailOn(
        GoRouter.of(tester.element(find.text(seedCase.title))),
        location,
      );
      await tester.pumpAndSettle();

      final list = find.byType(ListView).last;
      await tester.drag(list, const Offset(0, -2000));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)).first,
      );
      final listBottom = tester.getRect(list).bottom;
      final barTop = tester.getRect(find.byType(AppBottomNavBar)).top;
      // İçeriğin sonu = liste alt kenarı - alt boşluk; bar onu örtmemeli.
      final padding =
          (tester.widget<ListView>(list).padding!.resolve(TextDirection.ltr))
              .bottom;
      expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
      expect(listBottom - padding, lessThanOrEqualTo(barTop));
    });
  }
}
