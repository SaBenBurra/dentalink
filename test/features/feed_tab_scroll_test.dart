import 'package:dentigo/data/models/post_model.dart';
import 'package:dentigo/shared/widgets/post_glass_container.dart';
import 'package:dentigo/features/feed/screens/feed_screen.dart';
import 'package:dentigo/features/feed/widgets/feed_filter_segments.dart';
import 'package:dentigo/features/feed/widgets/feed_screen_app_bar.dart';
import 'package:dentigo/features/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';

void main() {
  testWidgets('feed sekmeleri arasında geçişte kaydırma konumu korunur', (
    tester,
  ) async {
    await pumpDentigo(tester, feed: _cases());

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

  testWidgets('logo yalnızca açık sekmeyi başa kaydırır', (tester) async {
    await pumpDentigo(tester, feed: _cases());
    Finder visible(String title) => find.text(title).hitTestable();
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
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.drag(visible('Vaka 0'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(0));

    // Logo üst barla birlikte gizli olabilir; geri çağrı doğrudan tetiklenir.
    tester.widget<FeedScreenAppBar>(find.byType(FeedScreenAppBar)).onLogoTap!();
    await tester.pumpAndSettle();
    expect(offset(), 0);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(offset(), allOffset);
  });

  testWidgets(
    'sekme kaydırması başlayınca gizli üst bar açılır, gösterge kaydırmayı izler; alt menü gizli kalır',
    (tester) async {
      await pumpDentigo(tester, feed: _cases());
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FeedScreen)),
      );
      double bottomBar() => container.read(bottomBarAnimationProvider).value;
      double header() => tester
          .widget<FeedScreenAppBar>(find.byType(FeedScreenAppBar))
          .visibility
          .value;
      final indicator = find.descendant(
        of: find.byType(FeedFilterSegments),
        matching: find.byType(Positioned),
      );
      final segment = tester.getSize(indicator).width;
      final start = tester.getTopLeft(indicator).dx;
      final width = tester.getSize(find.byType(PageView)).width;

      await tester.drag(
        find.text('Vaka 0').hitTestable(),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      expect(header(), 0);
      expect(bottomBar(), 0);

      // Çeyrek sayfa kaydır: üst bar hemen tamamen açılır, gösterge çeyrek
      // segment ilerler, alt menü gizli kalır.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-20, 0)); // sürükleme eşiği
      await gesture.moveBy(Offset(-width / 4, 0));
      await tester.pumpAndSettle();
      expect(header(), 1);
      expect(
        tester.getTopLeft(indicator).dx - start,
        closeTo(segment / 4, segment * 0.03),
      );
      expect(bottomBar(), 0);

      // Geri gel ve bırak: sekme değişmez, üst bar açık kalır.
      await gesture.moveBy(Offset(width / 4, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(header(), 1);
      expect(tester.getTopLeft(indicator).dx, start);

      // Aşağı kaydırınca üst bar yeniden gizlenir.
      await tester.drag(find.byType(PageView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(header(), 0);

      // Tam geçiş: üst bar yine açılır, gösterge bir segment ilerler.
      await tester.drag(find.byType(PageView), Offset(-width * 0.6, 0));
      await tester.pumpAndSettle();
      expect(header(), 1);
      expect(bottomBar(), 0);
      expect(tester.getTopLeft(indicator).dx - start, closeTo(segment, 0.5));

      // Aşağı kaydırınca üst bar yeniden gizlenir.
      await tester.drag(find.byType(PageView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(header(), 0);
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
      createdAt: DateTime(2024, 1, 20 - i),
      updatedAt: DateTime(2024),
      author: otherUser,
    ),
];
