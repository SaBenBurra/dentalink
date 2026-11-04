import 'package:dentigo/core/error/app_failures.dart';
import 'package:dentigo/data/repositories/otp_cooldown_exception.dart';
import 'package:dentigo/data/repositories/supabase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/generate_mocks.mocks.dart';

void main() {
  late MockGoTrueClient auth;
  late SupabaseAuthRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(client.auth).thenReturn(auth);
    repo = SupabaseAuthRepository(client: client);
  });

  test('telefona kod WhatsApp kanalından gider', () async {
    when(
      auth.signInWithOtp(
        phone: anyNamed('phone'),
        channel: anyNamed('channel'),
      ),
    ).thenAnswer((_) async {});

    await repo.sendOtp('0555 123 45 67');

    verify(
      auth.signInWithOtp(phone: '+905551234567', channel: OtpChannel.whatsapp),
    );
  });

  test('telefon değişiminde PUT /user gövdesi kanalı taşır', () async {
    when(auth.updateUser(any)).thenThrow(StateError('reached'));

    await expectLater(
      repo.requestContactChange('5551234567'),
      throwsStateError,
    );

    final attrs =
        verify(auth.updateUser(captureAny)).captured.single as UserAttributes;
    expect(attrs.toJson(), {'phone': '+905551234567', 'channel': 'whatsapp'});
  });

  test('e-posta değişiminde yalnızca e-posta gönderilir', () async {
    when(auth.updateUser(any)).thenThrow(StateError('reached'));

    await expectLater(
      repo.requestContactChange('Yeni@Klinik.Dental'),
      throwsStateError,
    );

    final attrs =
        verify(auth.updateUser(captureAny)).captured.single as UserAttributes;
    expect(attrs.toJson(), {'email': 'yeni@klinik.dental'});
  });

  group('sunucu limiti', () {
    void stubSend(AuthApiException error) => when(
      auth.signInWithOtp(
        phone: anyNamed('phone'),
        channel: anyNamed('channel'),
      ),
    ).thenThrow(error);

    test('sıklık sınırı kalan süreyi taşır', () async {
      stubSend(
        const AuthApiException(
          'For security purposes, you can only request this after 42 seconds.',
          statusCode: '429',
          code: 'over_sms_send_rate_limit',
        ),
      );

      await expectLater(
        repo.sendOtp('5551234567'),
        throwsA(
          isA<OtpCooldownException>().having(
            (e) => e.remainingSeconds,
            'remainingSeconds',
            42,
          ),
        ),
      );
    });

    test('genel limitte kod gitmediği için cooldown sayılmaz', () async {
      stubSend(
        const AuthApiException(
          'SMS rate limit exceeded',
          statusCode: '429',
          code: 'over_sms_send_rate_limit',
        ),
      );

      await expectLater(
        repo.sendOtp('5551234567'),
        throwsA(isA<AuthApiException>()),
      );
    });
  });

  test('geçersiz adres sunucuya gitmez', () async {
    await expectLater(
      repo.sendOtp('merhaba'),
      throwsA(isA<ValidationFailure>()),
    );
    verifyZeroInteractions(auth);
  });
}
