import 'dart:async';

import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

class _Auth extends MockAuthForTest {
  _Auth({required this.session});

  final bool session;
  final profile = Completer<UserModel?>();
  int sent = 0;

  @override
  bool get hasSession => session;

  @override
  Future<UserModel?> getCurrentUser() =>
      session ? profile.future : Future.value(null);

  @override
  Future<void> sendOtp(String emailOrPhone) async => sent++;
}

Future<void> _pump(WidgetTester tester, _Auth auth) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('oturum geri yüklenirken giriş formu görünmez', (tester) async {
    await _pump(tester, _Auth(session: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('geçersiz girişte açıklama çıkar, düzeltince kalkar', (
    tester,
  ) async {
    final auth = _Auth(session: false);
    await _pump(tester, auth);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();

    expect(find.textContaining('Türkiye WhatsApp numarası'), findsOneWidget);
    expect(auth.sent, 0);

    await tester.enterText(find.byType(TextField), '5551234567');
    await tester.pump();
    expect(find.textContaining('Türkiye WhatsApp numarası'), findsNothing);
  });
}
