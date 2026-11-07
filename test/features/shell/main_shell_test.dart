import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/features/shell/main_shell.dart';
import 'package:dentigo/providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _list(int count, {Key? key}) => ListView.builder(
  key: key,
  itemCount: count,
  itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
);

StatefulShellBranch _branch(String path, WidgetBuilder builder) =>
    StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (context, _) => builder(context))],
    );

Future<ProviderContainer> _pumpShell(
  WidgetTester tester, {
  required String initialLocation,
  required WidgetBuilder feed,
  required WidgetBuilder search,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          _branch('/feed', feed),
          _branch('/search', search),
          _branch('/messages', (_) => const SizedBox()),
          _branch('/profile', (_) => const SizedBox()),
        ],
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [totalUnreadMessagesProvider.overrideWith((ref) => 0)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'gizli alt menü, içerik kaydırılamayacak kadar kısalınca geri gelir',
    (tester) async {
      final itemCount = ValueNotifier(100);
      final container = await _pumpShell(
        tester,
        initialLocation: '/search',
        feed: (_) => const SizedBox(),
        search: (_) => ValueListenableBuilder<int>(
          valueListenable: itemCount,
          builder: (_, count, _) => _list(count),
        ),
      );
      final bar = container.read(bottomBarControllerProvider);
      expect(bar.isVisible, isTrue);

      // Aşağı kaydırınca bar gizlenir.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(bar.isVisible, isFalse);

      // Liste boşaldı (ör. post olmayan branş): kaydıracak yer yok, bar döner.
      itemCount.value = 0;
      await tester.pumpAndSettle();
      expect(bar.isVisible, isTrue);
    },
  );

  testWidgets('sekme değişince ekran yeniden kurulmaz, kaydırma korunur', (
    tester,
  ) async {
    var feedBuilds = 0;
    const feedKey = Key('feed');
    final container = await _pumpShell(
      tester,
      initialLocation: '/feed',
      feed: (_) {
        feedBuilds++;
        return _list(100, key: feedKey);
      },
      search: (_) => const Text('keşfet'),
    );

    // Kaydırınca alt menü gizlenir; sekmeye dokunabilmek için geri getirilir.
    await tester.drag(find.byKey(feedKey), const Offset(0, -800));
    await tester.pumpAndSettle();
    final offset = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(feedKey),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(offset, greaterThan(0));
    container.read(bottomBarControllerProvider).show();
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(MainShell)))!;
    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    expect(find.byKey(feedKey), findsNothing);

    await tester.tap(find.text(l10n.navFeed));
    await tester.pumpAndSettle();
    expect(feedBuilds, 1);
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(feedKey),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels,
      offset,
    );
  });
}
