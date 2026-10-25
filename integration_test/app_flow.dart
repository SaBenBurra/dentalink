import 'package:dentlink/main.dart';
import 'package:dentlink/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repositories.dart';

/// Uygulamayı fake repository'lerle açar. Cihazda (integration_test/) ve
/// headless (test/, CI) aynı akış çalışır.
Future<void> pumpDentLink(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakeRepositoryOverrides(),
        // Metinler cihaz dilinden bağımsız olsun (emülatör TR, headless EN açılır).
        localeModeProvider.overrideWith(_TurkishLocale.new),
      ],
      child: const MainApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _TurkishLocale extends LocaleModeNotifier {
  @override
  Locale build() => const Locale('tr');
}

/// Ekrandaki geri kontrolüne basar; yoksa test düşer.
Future<void> _goBack(WidgetTester tester) async {
  final candidates = [
    find.byType(BackButton),
    find.byIcon(Icons.arrow_back_ios_new_rounded),
    find.byIcon(Icons.arrow_back),
  ];
  final back = candidates.firstWhere(
    (f) => f.evaluate().isNotEmpty,
    orElse: () => throw TestFailure('Geri butonu bulunamadı'),
  );
  await tester.tap(back.last);
  await tester.pumpAndSettle();
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> runAppFlow(WidgetTester tester) async {
  await pumpDentLink(tester);

  // Feed: oturum açık, örnek vaka listede.
  expect(find.text(seedCase.title), findsOneWidget);

  // Vaka detayı ve geri.
  await _tapAndSettle(tester, find.text(seedCase.title));
  expect(find.text(seedCase.content), findsOneWidget);
  await _goBack(tester);
  expect(find.text(seedCase.title), findsOneWidget);

  // Bildirimler: zil → takip bildirimi.
  await _tapAndSettle(tester, find.byTooltip('Bildirimler'));
  expect(find.textContaining(otherUser.fullName), findsWidgets);
  await _goBack(tester);

  // Keşfet.
  await _tapAndSettle(tester, find.text('Keşfet'));
  expect(find.byType(TextField), findsWidgets);

  // Mesajlar → sohbet → geri.
  await _tapAndSettle(tester, find.text('Mesajlar'));
  expect(find.text(otherUser.fullName), findsOneWidget);
  await _tapAndSettle(tester, find.text(otherUser.fullName));
  expect(find.text('Merhaba'), findsWidgets);
  await _goBack(tester);

  // Profil → ayarlar → geri → profili düzenle → geri.
  await _tapAndSettle(tester, find.text('Profil'));
  expect(find.text('Test User'), findsWidgets);
  await _tapAndSettle(tester, find.byTooltip('Ayarlar'));
  await _goBack(tester);
  await _tapAndSettle(tester, find.text('Profili Düzenle'));
  await _goBack(tester);

  // Oluştur (+) → vaka formu → geri; soru formu → geri.
  await _tapAndSettle(tester, find.text('Ana Sayfa'));
  await _tapAndSettle(tester, find.byIcon(Icons.add_rounded));
  await _tapAndSettle(tester, find.text('Vaka Paylaş'));
  expect(find.byType(TextFormField), findsWidgets);
  await _goBack(tester);
  await _tapAndSettle(tester, find.byIcon(Icons.add_rounded));
  await _tapAndSettle(tester, find.text('Soru Sor'));
  expect(find.byType(TextFormField), findsWidgets);
  await _goBack(tester);

  expect(find.text(seedCase.title), findsOneWidget);
}
