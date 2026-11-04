import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/features/settings/screens/change_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;

import '../../integration_test/mock_auth_for_test.dart';

class _Auth extends MockAuthForTest {
  final sent = <String>[];
  Object? sendError;
  UserModel user = UserModel(
    id: 'u',
    email: 'eski@klinik.co',
    phone: '905551234567',
    fullName: 'Test',
    username: 'test',
    title: UserTitle.ogrenci,
    onboardingCompleted: true,
    createdAt: DateTime(2026),
  );

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<void> requestContactChange(String emailOrPhone) async {
    if (sendError != null) throw sendError!;
    sent.add(emailOrPhone);
  }

  @override
  Future<UserModel?> confirmContactChange(
    String emailOrPhone,
    String otpCode,
  ) async {
    if (otpCode != '123456') {
      throw const AuthApiException('bad', code: 'otp_expired');
    }
    return user = user.copyWith(email: emailOrPhone);
  }
}

Future<void> _pump(WidgetTester tester, _Auth auth, bool isEmail) async {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('ayarlar')),
        routes: [
          GoRoute(
            path: 'contact',
            builder: (_, _) => ChangeContactScreen(isEmail: isEmail),
          ),
        ],
      ),
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
  await tester.pumpAndSettle();
  router.push('/settings/contact');
  await tester.pumpAndSettle();
  // authProvider yüklensin.
  await tester.pump();
}

void main() {
  testWidgets('kod yanlışsa hata, doğruysa kaydedip geri döner', (
    tester,
  ) async {
    final auth = _Auth();
    await _pump(tester, auth, true);

    await tester.enterText(find.byType(TextField), 'Yeni@Klinik.co');
    await tester.pump();
    await tester.tap(find.text('Kod Gönder'));
    await tester.pump();
    await tester.pump();
    expect(auth.sent, ['yeni@klinik.co']);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Doğrula'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Kod hatalı veya süresi dolmuş'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Doğrula'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('ayarlar'), findsOneWidget);
    expect(auth.user.email, 'yeni@klinik.co');
  });

  testWidgets('aynı numara ve başka hesaptaki numara ilk adımda kalır', (
    tester,
  ) async {
    final auth = _Auth();
    await _pump(tester, auth, false);

    await tester.enterText(find.byType(TextField), '05551234567');
    await tester.pump();
    await tester.tap(find.text('Kod Gönder'));
    await tester.pump();
    expect(find.text('Bu zaten hesabınızda kayıtlı.'), findsOneWidget);
    expect(auth.sent, isEmpty);

    auth.sendError = const AuthApiException('dup', code: 'phone_exists');
    await tester.enterText(find.byType(TextField), '05559999999');
    await tester.pump();
    await tester.tap(find.text('Kod Gönder'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Bu bilgi başka bir hesapta kayıtlı.'), findsOneWidget);
  });
}
