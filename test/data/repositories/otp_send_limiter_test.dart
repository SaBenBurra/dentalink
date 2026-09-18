import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/repositories/otp_send_limiter.dart';
import 'package:dentlink/data/repositories/otp_cooldown_exception.dart';

void main() {
  late OtpSendLimiter limiter;

  setUp(() {
    // persist: false — SharedPreferences kullanmadan bellekte çalışır
    limiter = OtpSendLimiter(
      cooldown: const Duration(seconds: 60),
      maxDistinctDestinations: 2,
      persist: false,
    );
  });

  group('OtpSendLimiter -', () {
    test('check returns null for first send (no block)', () async {
      await limiter.ensureLoaded();
      final result = limiter.check('test@example.com');
      expect(result, isNull);
    });

    test('check blocks same destination after recordSuccess', () async {
      await limiter.ensureLoaded();
      await limiter.recordSuccess('test@example.com');

      final result = limiter.check('test@example.com');

      expect(result, isNotNull);
      expect(result, isA<OtpCooldownException>());
      expect(result!.sameDestination, isTrue);
      expect(result.remainingSeconds, greaterThan(0));
      expect(result.remainingSeconds, lessThanOrEqualTo(60));
    });

    test('check allows different destination after first send', () async {
      await limiter.ensureLoaded();
      await limiter.recordSuccess('test@example.com');

      // İkinci farklı hedef serbest olmalı
      final result = limiter.check('other@example.com');
      expect(result, isNull);
    });

    test('check blocks when maxDistinctDestinations exceeded', () async {
      await limiter.ensureLoaded();
      // 2 farklı hedefe gönder (maxDistinctDestinations = 2)
      await limiter.recordSuccess('first@example.com');
      await limiter.recordSuccess('second@example.com');

      // 3. farklı hedef engellenmeli
      final result = limiter.check('third@example.com');

      expect(result, isNotNull);
      expect(result!.sameDestination, isFalse);
      expect(result.remainingSeconds, greaterThan(0));
    });

    test('hasSentTo returns false before any send', () async {
      await limiter.ensureLoaded();
      expect(limiter.hasSentTo('test@example.com'), isFalse);
    });

    test('hasSentTo returns true after recordSuccess', () async {
      await limiter.ensureLoaded();
      await limiter.recordSuccess('test@example.com');

      expect(limiter.hasSentTo('test@example.com'), isTrue);
    });

    test('hasSentTo returns false for unsent destination', () async {
      await limiter.ensureLoaded();
      await limiter.recordSuccess('sent@example.com');

      expect(limiter.hasSentTo('unsent@example.com'), isFalse);
    });

    test('touchRateLimit refreshes cooldown for same destination', () async {
      await limiter.ensureLoaded();
      await limiter.recordSuccess('test@example.com');

      // Touch rate limit: eski kaydı kaldırır ve yeni zaman damgası ekler
      await limiter.touchRateLimit('test@example.com');

      final result = limiter.check('test@example.com');
      expect(result, isNotNull);
      // Cooldown yenilendi, hâlâ engelli
      expect(result!.remainingSeconds, greaterThan(0));
    });

    test('ensureLoaded can be called multiple times safely', () async {
      await limiter.ensureLoaded();
      await limiter.ensureLoaded();
      await limiter.ensureLoaded();

      // No error, idempotent
      final result = limiter.check('test@example.com');
      expect(result, isNull);
    });

    test('short cooldown limiter expires quickly', () async {
      // 0 saniyelik cooldown ile test
      final shortLimiter = OtpSendLimiter(
        cooldown: Duration.zero,
        maxDistinctDestinations: 2,
        persist: false,
      );
      await shortLimiter.ensureLoaded();
      await shortLimiter.recordSuccess('test@example.com');

      // Cooldown sıfır olduğunda prune anında temizler
      final result = shortLimiter.check('test@example.com');
      expect(result, isNull);
    });
  });

  group('OtpCooldownException -', () {
    test('toString contains remaining seconds', () {
      const exception = OtpCooldownException(
        remainingSeconds: 45,
        sameDestination: true,
      );

      final str = exception.toString();
      expect(str, contains('45'));
      expect(str, contains('true'));
    });

    test('implements Exception', () {
      const exception = OtpCooldownException(
        remainingSeconds: 30,
        sameDestination: false,
      );
      expect(exception, isA<Exception>());
    });
  });
}
