import 'dart:async';

import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/features/settings/widgets/sign_out_dialog.dart';
import 'package:dentigo/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

/// Çıkış [gate] tamamlanana kadar sürer.
class _SlowAuth extends MockAuthForTest {
  final gate = Completer<void>();

  @override
  Future<void> signOut() async {
    await gate.future;
    await super.signOut();
  }
}

void main() {
  testWidgets('çıkış sürerken yükleniyor gösterilir', (tester) async {
    final auth = _SlowAuth();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const SignOutDialog(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('tr'));
    await tester.tap(find.text(l10n.settingsLogout));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.gate.complete();
    await tester.pump();
    expect(container.read(authProvider).value, isNull);
  });
}
