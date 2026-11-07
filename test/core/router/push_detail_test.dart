import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/core/router/app_router.dart';
import 'package:dentigo/features/shell/main_shell.dart';
import 'package:dentigo/providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRoute _post({bool root = false}) => GoRoute(
  path: root ? '/post/:id' : 'post/:id',
  builder: (_, state) => Text('post ${state.pathParameters['id']}'),
);

StatefulShellBranch _branch(String path) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (_, _) => Text('kök $path'),
      routes: [_post()],
    ),
  ],
);

Future<GoRouter> _pump(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          _branch('/feed'),
          _branch('/search'),
          _branch('/messages'),
          _branch('/profile'),
        ],
      ),
      GoRoute(path: '/chat', builder: (_, _) => const Text('sohbet')),
      _post(root: true),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [totalUnreadMessagesProvider.overrideWith((ref) => 0)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _location(GoRouter router) => router.state.uri.toString();

void main() {
  test('yalnızca detay sayfaları sekmenin altına taşınır', () {
    expect(
      detailLocationIn('/feed', '/post/1?comments=1'),
      '/feed/post/1?comments=1',
    );
    expect(detailLocationIn('/profile', '/profile/u1'), '/profile/profile/u1');
    expect(detailLocationIn('/feed', '/chat/u1?name=a'), '/chat/u1?name=a');
    expect(detailLocationIn(null, '/post/1'), '/post/1');
  });

  testWidgets(
    'detay açık sekmede açılır, alt menü görünür; sekmeye dokununca köke döner',
    (tester) async {
      final router = await _pump(tester);
      pushDetailOn(router, '/post/1');
      await tester.pumpAndSettle();
      pushDetailOn(router, '/post/2');
      await tester.pumpAndSettle();

      expect(_location(router), '/search/post/2');
      expect(find.text('post 2'), findsOneWidget);
      final l10n = AppLocalizations.of(tester.element(find.byType(MainShell)))!;
      expect(find.text(l10n.navExplore), findsOneWidget);

      await tester.tap(find.text(l10n.navExplore));
      await tester.pumpAndSettle();
      expect(_location(router), '/search');
      expect(find.text('kök /search'), findsOneWidget);
    },
  );

  testWidgets('sekme dışı sayfadan detay kökte açılır', (tester) async {
    final router = await _pump(tester);
    router.push('/chat');
    await tester.pumpAndSettle();
    pushDetailOn(router, '/post/1');
    await tester.pumpAndSettle();

    expect(_location(router), '/post/1');
    expect(find.text('post 1'), findsOneWidget);
  });
}
