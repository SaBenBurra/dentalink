import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/features/auth/providers/login_controller.dart';
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
      overrides: [authRepositoryProvider.overrideWithValue(auth)]);
  addTearDown(c.dispose);
  c.listen(loginControllerProvider, (_, _) {});
  return c;
}

void main() {
  test('reddedilen kod "hatalı", ağ hatası bağlantı mesajı gösterir (AUTH-10)',
      () async {
    final auth = _ThrowingAuth()
      ..verifyError = const AuthApiException('bad', code: 'otp_expired');
    final c = _container(auth);
    final ctrl = c.read(loginControllerProvider.notifier);

    await ctrl.verifyOtp('a@b.co', '123456');
    expect(c.read(loginControllerProvider).errorText,
        'Kod hatalı veya süresi dolmuş');

    auth.verifyError = AuthRetryableFetchException();
    await ctrl.verifyOtp('a@b.co', '123456');
    expect(c.read(loginControllerProvider).errorText,
        'İnternet bağlantınızı kontrol edin.');
  });

  test('gönderim hatasında ham Exception metni çıkmaz, geri sayım 60 sn',
      () async {
    final auth = _ThrowingAuth()..sendError = Exception('boom');
    final c = _container(auth);
    final ctrl = c.read(loginControllerProvider.notifier);

    await ctrl.sendOtp('a@b.co');
    expect(c.read(loginControllerProvider).errorText,
        isNot(contains('Exception')));

    auth.sendError = null;
    await ctrl.sendOtp('a@b.co');
    expect(c.read(loginControllerProvider).resendCountdown, 60);
  });
}
