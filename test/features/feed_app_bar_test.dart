import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/feed/widgets/feed_filter_segments.dart';
import 'package:dentlink/features/feed/widgets/feed_screen_app_bar.dart';
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
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationCountProvider.overrideWith((ref) => 0)],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
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
    },
  );

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
