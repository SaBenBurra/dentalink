import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/shell/main_shell.dart';
import 'package:dentlink/providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'gizli alt menü, içerik kaydırılamayacak kadar kısalınca geri gelir',
    (tester) async {
      final itemCount = ValueNotifier(100);
      final router = GoRouter(
        initialLocation: '/search',
        routes: [
          ShellRoute(
            builder: (_, _, child) => MainShell(child: child),
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, _) => ValueListenableBuilder<int>(
                  valueListenable: itemCount,
                  builder: (_, count, _) => ListView.builder(
                    itemCount: count,
                    itemBuilder: (_, i) =>
                        SizedBox(height: 80, child: Text('$i')),
                  ),
                ),
              ),
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
}
