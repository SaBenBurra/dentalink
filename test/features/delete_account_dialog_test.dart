import 'dart:async';

import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/user_repository.dart';
import 'package:dentlink/features/settings/widgets/delete_account_dialog.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

class _UserRepo implements UserRepository {
  int calls = 0;
  Completer<void> gate = Completer();

  @override
  Future<void> deleteAccount() {
    calls++;
    return gate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _UserRepo repo;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    repo = _UserRepo();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthForTest()),
      userRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const DeleteAccountDialog(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  TextButton deleteButton(WidgetTester tester) => tester.widget<TextButton>(
        find.ancestor(of: find.text('Hesabı Sil'), matching: find.byType(TextButton)),
      );

  testWidgets('onay kelimesi yazılmadan silinmez; silerken kilitli; başarıda oturum kapanır',
      (tester) async {
    await pump(tester);
    expect(deleteButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'sil');
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNull, reason: 'büyük/küçük harf eşleşmeli');

    await tester.enterText(find.byType(TextField), 'SİL');
    await tester.pump();
    await tester.tap(find.text('Hesabı Sil'));
    await tester.pump();

    // Silinirken: ikinci basış ve iptal yok.
    final cancel = find.ancestor(of: find.text('İptal'), matching: find.byType(TextButton));
    expect(tester.widget<TextButton>(cancel).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget); // sil butonu kilitli
    expect(repo.calls, 1);

    repo.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountDialog), findsNothing);
    expect(container.read(authProvider).value, isNull);
  });

  testWidgets('hata olursa mesaj gösterilir, kullanıcı oturumda kalır, tekrar denenebilir',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'SİL');
    await tester.pump();
    await tester.tap(find.text('Hesabı Sil'));
    await tester.pump();

    repo.gate.completeError(const NetworkFailure());
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    expect(find.textContaining('bağlantı', findRichText: true), findsWidgets);
    expect(container.read(authProvider).value, isNotNull);
    expect(deleteButton(tester).onPressed, isNotNull);
  });
}
