import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/shared/widgets/unsaved_changes_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _pump(WidgetTester tester, {required bool dirty, bool busy = false}) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => TextButton(
        onPressed: () => context.push('/form'),
        child: const Text('home'),
      ),
    ),
    GoRoute(
      path: '/form',
      builder: (context, _) => UnsavedChangesScope(
        dirty: dirty,
        busy: busy,
        child: Scaffold(
          appBar: AppBar(),
          // Kaydettikten sonraki programatik çıkış.
          body: TextButton(onPressed: () => context.pop(), child: const Text('saved')),
        ),
      ),
    ),
  ]);
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
  await tester.tap(find.text('home'));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('temiz formda geri doğrudan çıkar', (tester) async {
    await _pump(tester, dirty: false);
    await _back(tester);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('dolu formda geri onay ister; İptal kalır, Çık çıkar (UX-2)', (tester) async {
    await _pump(tester, dirty: true);
    await _back(tester);
    expect(find.text('Değişiklikler kaybolacak'), findsOneWidget);

    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(find.text('saved'), findsOneWidget);

    await _back(tester);
    await tester.tap(find.text('Çık'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('gönderilirken geri hiçbir şey yapmaz', (tester) async {
    await _pump(tester, dirty: true, busy: true);
    await _back(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('saved'), findsOneWidget);
  });

  testWidgets('kaydettikten sonra context.pop engellenmez', (tester) async {
    await _pump(tester, dirty: true);
    await tester.tap(find.text('saved'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
