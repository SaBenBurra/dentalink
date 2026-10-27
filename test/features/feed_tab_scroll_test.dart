import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/shared/widgets/post_glass_container.dart';
import 'package:dentlink/features/feed/screens/feed_screen.dart';
import 'package:dentlink/features/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';

void main() {
  testWidgets('feed sekmeleri arasında geçişte kaydırma konumu korunur', (
    tester,
  ) async {
    await pumpDentLink(tester, feed: _cases());

    Finder visible(String title) => find.text(title).hitTestable();
    // Ekrandaki dikey liste: görünen bir kartın en yakın Scrollable atası.
    double offset() => tester
        .state<ScrollableState>(
          find
              .ancestor(
                of: find.byType(PostGlassContainer).hitTestable().first,
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .pixels;

    await tester.drag(visible('Vaka 0'), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final allOffset = offset();
    expect(allOffset, greaterThan(0));

    // Üst bar kaydırınca gizlendi; sekmeler arası yatay kaydırmayla geçilir.
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(visible('Vaka 0'), findsOneWidget); // yeni sekme baştan
    await tester.drag(visible('Vaka 0'), const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(visible('Vaka 0'), findsNothing);
    expect(offset(), allOffset);
  });

  testWidgets(
    'gizli barlar yan sekmeye kaydırma oranında görünür, vazgeçince gizlenir',
    (tester) async {
      await pumpDentLink(tester, feed: _cases());
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FeedScreen)),
      );
      double bars() => container.read(bottomBarAnimationProvider).value;
      final width = tester.getSize(find.byType(PageView)).width;

      await tester.drag(
        find.text('Vaka 0').hitTestable(),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      expect(bars(), 0);

      // Çeyrek sayfa kaydır: barlar da çeyrek görünür.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-20, 0)); // sürükleme eşiği
      await gesture.moveBy(Offset(-width / 4, 0));
      await tester.pump();
      expect(bars(), closeTo(0.25, 0.03));

      // Geri gel ve bırak: sekme değişmez, barlar yeniden gizlenir.
      await gesture.moveBy(Offset(width / 4, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(bars(), 0);

      // Tam geçiş: barlar tamamen görünür ve öyle kalır.
      await tester.drag(find.byType(PageView), Offset(-width * 0.6, 0));
      await tester.pumpAndSettle();
      expect(bars(), 1);
      expect(container.read(bottomBarControllerProvider).isVisible, isTrue);
      expect(container.read(bottomBarRevealProvider).value, 0);
    },
  );
}

List<CasePostModel> _cases() => [
  for (var i = 0; i < 20; i++)
    CasePostModel(
      id: 'c$i',
      userId: otherUser.id,
      title: 'Vaka $i',
      content: 'İçerik $i',
      branch: DentalBranch.endodonti,
      createdAt: DateTime(2024, 1, 20 - i),
      updatedAt: DateTime(2024),
      author: otherUser,
    ),
];
