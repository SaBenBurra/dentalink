import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/data/repositories/otp_cooldown_exception.dart';
import 'package:dentigo/features/auth/providers/login_controller.dart';
import 'package:dentigo/providers/locale_provider.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthApiException, AuthRetryableFetchException;

import '../../integration_test/mock_auth_for_test.dart';

class _ThrowingAuth extends MockAuthForTest {
  Object? verifyError;
  Object? sendError;

  @override
  Future<void> sendOtp(String emailOrPhone) async {
    if (sendError != null) throw sendError!;
  }

  @override
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    throw verifyError!;
  }
}

ProviderContainer _container(_ThrowingAuth auth) {
  final c = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      l10nProvider.overrideWithValue(
        lookupAppLocalizations(const Locale('tr')),
      ),
    ],
  );
  addTearDown(c.dispose);
  c.listen(loginControllerProvider, (_, _) {});
  return c;
}

void main() {
  test('çok deneme ve WhatsApp hatası kendi mesajıyla çıkar', () async {
    final auth = _ThrowingAuth()
      ..verifyError = const AuthApiException(
        'slow down',
        statusCode: '429',
        code: 'over_request_rate_limit',
      );
    final c = _container(auth);
    final ctrl = c.read(loginControllerProvider.notifier);

    await ctrl.verifyOtp('a@b.co', '123456');
    expect(
      c.read(loginControllerProvider).errorText,
      'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.',
    );

    auth.sendError = const AuthApiException('fail', code: 'sms_send_failed');
    await ctrl.sendOtp('5551234567');
    expect(
      c.read(loginControllerProvider).errorText,
      startsWith("WhatsApp'a kod gönderilemedi"),
    );
  });

  test('yeniden gönderim hatası WhatsApp mesajını gösterir', () async {
    // Süresi bitmiş cooldown OTP adımını yeniden gönderime hazır açar.
    final auth = _ThrowingAuth()
      ..sendError = const OtpCooldownException(
        remainingSeconds: 0,
        sameDestination: true,
      );
    final c = _container(auth);
    final ctrl = c.read(loginControllerProvider.notifier);

    await ctrl.sendOtp('5551234567');
    auth.sendError = const AuthApiException('fail', code: 'sms_send_failed');
    await ctrl.resendOtp('5551234567');

    expect(
      c.read(loginControllerProvider).errorText,
      startsWith("WhatsApp'a kod gönderilemedi"),
    );
  });

  test(
    'reddedilen kod "hatalı", ağ hatası bağlantı mesajı gösterir (AUTH-10)',
    () async {
      final auth = _ThrowingAuth()
        ..verifyError = const AuthApiException('bad', code: 'otp_expired');
      final c = _container(auth);
      final ctrl = c.read(loginControllerProvider.notifier);

      await ctrl.verifyOtp('a@b.co', '123456');
      expect(
        c.read(loginControllerProvider).errorText,
        'Kod hatalı veya süresi dolmuş',
      );

      auth.verifyError = AuthRetryableFetchException();
      await ctrl.verifyOtp('a@b.co', '123456');
      expect(
        c.read(loginControllerProvider).errorText,
        'İnternet bağlantınızı kontrol edin.',
      );
    },
  );

  test(
    'gönderim hatasında ham Exception metni çıkmaz, geri sayım 60 sn',
    () async {
      final auth = _ThrowingAuth()..sendError = Exception('boom');
      final c = _container(auth);
      final ctrl = c.read(loginControllerProvider.notifier);

      await ctrl.sendOtp('a@b.co');
      expect(
        c.read(loginControllerProvider).errorText,
        isNot(contains('Exception')),
      );

      auth.sendError = null;
      await ctrl.sendOtp('a@b.co');
      expect(c.read(loginControllerProvider).resendCountdown, 60);
    },
  );
}
