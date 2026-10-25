import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/feed/widgets/feed_filter_segments.dart';
import 'package:dentlink/features/feed/widgets/feed_screen_app_bar.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _pumpSegments(
  WidgetTester tester,
  List<String> labels, {
  required ValueGetter<int> selected,
  required ValueChanged<int> onSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) => FeedFilterSegments(
                labels: labels,
                selectedIndex: selected(),
                onSelected: (i) => setState(() => onSelected(i)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'app bar: segment dokunuşu index verir; arama /search\'e götürür',
    (tester) async {
      var index = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => StatefulBuilder(
              builder: (context, setState) => Scaffold(
                appBar: FeedScreenAppBar(
                  labels: const ['Tümü', 'Vakalar', 'Sorular'],
                  selectedIndex: index,
                  onSelected: (i) => setState(() => index = i),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/search',
            builder: (_, _) => const Text('search page'),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Text('profile page'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      // Sekmeler ortalının 16dp soluna uzatılmış: merkez 8dp solda.
      final screenW =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getCenter(find.byType(FeedFilterSegments)).dx,
        closeTo(screenW / 2 - 8, 0.01),
      );

      await tester.tap(find.text('Sorular'));
      await tester.pumpAndSettle();
      expect(index, 2);
      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      expect(index, 0);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.text('search page'), findsOneWidget);

      // Avatar → Profil sekmesi.
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('profile page'), findsOneWidget);
    },
  );

  testWidgets('visibility 0 iken bar kayar ve yer kaplamaz', (tester) async {
    Future<Size> pumpAt(double v) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  FeedScreenAppBar(
                    labels: const ['A', 'B'],
                    selectedIndex: 0,
                    onSelected: (_) {},
                    visibility: AlwaysStoppedAnimation(v),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(FeedScreenAppBar));
    }

    expect((await pumpAt(1)).height, 56);
    expect((await pumpAt(0.5)).height, 28);
    // Yay 0'ın altına taşsa da yükseklik negatif olmaz.
    expect((await pumpAt(-0.2)).height, 0);
    expect(find.byTooltip('Profil').hitTestable(), findsNothing);
  });

  testWidgets('3 segment rayı tam doldurur ve kaymaz', (tester) async {
    await _pumpSegments(
      tester,
      ['A', 'B', 'C'],
      selected: () => 0,
      onSelected: (_) {},
    );
    final ray = tester.getRect(find.byType(FeedFilterSegments));
    final last = tester.getRect(
      find.ancestor(of: find.text('C'), matching: find.byType(SizedBox)).first,
    );
    expect(last.right, closeTo(ray.right - 2.5, 0.01));
  });

  testWidgets(
    '4+ segmentte 4. segmentin yarısı görünür; seçilen ortaya kayar',
    (tester) async {
      var index = 0;
      await _pumpSegments(
        tester,
        ['A', 'B', 'C', 'D', 'E'],
        selected: () => index,
        onSelected: (i) => index = i,
      );
      final ray = tester.getRect(find.byType(FeedFilterSegments));
      Rect seg(String l) => tester.getRect(
        find.ancestor(of: find.text(l), matching: find.byType(SizedBox)).first,
      );

      // 4. segment rayın sağ kenarında kesik: başı içeride, sonu dışarıda.
      expect(seg('D').left, lessThan(ray.right));
      expect(seg('D').right, greaterThan(ray.right));

      // Dışarıdan seçim (sayfa kaydırma) E'yi görünür alana getirir.
      await tester.tap(find.text('D'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(index, 3);
      index = 4;
      await _pumpSegments(
        tester,
        ['A', 'B', 'C', 'D', 'E'],
        selected: () => index,
        onSelected: (i) => index = i,
      );
      await tester.pumpAndSettle();
      expect(seg('E').right, lessThanOrEqualTo(ray.right + 0.01));
    },
  );

  test('kenar solması yalnızca devamı olan yönde', () {
    expect(edgeFades(_metrics(0, 0)), (false, false)); // 3 sekme, kaymaz
    expect(edgeFades(_metrics(0, 100)), (false, true));
    expect(edgeFades(_metrics(50, 100)), (true, true));
    expect(edgeFades(_metrics(100, 100)), (true, false));
  });
}

ScrollMetrics _metrics(double pixels, double max) => FixedScrollMetrics(
  minScrollExtent: 0,
  maxScrollExtent: max,
  pixels: pixels,
  viewportDimension: 300,
  axisDirection: AxisDirection.right,
  devicePixelRatio: 1,
);
