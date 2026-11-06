import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/features/auth/providers/login_controller.dart';
import 'package:dentigo/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../integration_test/mock_auth_for_test.dart';

class _Auth extends MockAuthForTest {
  String? code;

  @override
  bool get hasSession => false;

  @override
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    code = otpCode;
    return null;
  }
}

Finder get _otpField => find.byWidgetPredicate(
  (w) => w is TextField && w.keyboardType == TextInputType.number,
);

Future<void> _pumpOtpStep(WidgetTester tester, _Auth auth) async {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const SizedBox()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp.router(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LoginScreen)),
  );
  await tester.enterText(find.byType(TextField), '5551234567');
  await container.read(loginControllerProvider.notifier).sendOtp('5551234567');
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  expect(_otpField, findsOneWidget);
}

void main() {
  testWidgets('dolu alana yapıştırılan kod eksiksiz doğrulanır', (
    tester,
  ) async {
    final auth = _Auth();
    await _pumpOtpStep(tester, auth);

    await tester.enterText(_otpField, '9');
    await tester.pump();
    await tester.enterText(_otpField, '9123456');
    await tester.pump(const Duration(seconds: 2));

    expect(auth.code, '123456');
  });

  testWidgets('silinen hane kutudan kalkar, yeni hane yerine geçer', (
    tester,
  ) async {
    final auth = _Auth();
    await _pumpOtpStep(tester, auth);

    await tester.enterText(_otpField, '123');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3'), findsOneWidget);

    await tester.enterText(_otpField, '12');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3'), findsNothing);

    await tester.enterText(_otpField, '124567');
    await tester.pump(const Duration(seconds: 2));
    expect(auth.code, '124567');
  });

  testWidgets('gizli alan temadan çerçeve almaz', (tester) async {
    await _pumpOtpStep(tester, _Auth());

    await tester.tap(_otpField);
    await tester.pump();

    expect(
      find.descendant(of: _otpField, matching: find.byType(InputDecorator)),
      findsNothing,
    );
  });

  testWidgets('Android geri tuşu kod ekranından girişe döner', (tester) async {
    await _pumpOtpStep(tester, _Auth());

    final handled = await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(handled, isTrue);
    expect(_otpField, findsNothing);
    expect(find.text('5551234567'), findsOneWidget);
  });
}
