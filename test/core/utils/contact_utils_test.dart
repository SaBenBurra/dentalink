import 'package:dentigo/core/utils/contact_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Türkiye cep numarasının yazımları aynı E.164 numaraya iner', () {
    for (final input in [
      '5551234567',
      '05551234567',
      '905551234567',
      '+905551234567',
      '0090 555 123 45 67',
      '+90 (555) 123-45-67',
    ]) {
      expect(normalizePhone(input), '+905551234567', reason: input);
    }
  });

  test('ülke kodlu yabancı numara kalır, belirsiz numara reddedilir', () {
    expect(normalizePhone('+49 151 23456789'), '+4915123456789');
    expect(normalizePhone('12345678'), isNull);
    expect(normalizePhone('02121234567'), isNull);
    expect(normalizePhone('+0555123456'), isNull);
  });

  test('e-posta küçük harfe iner, uzun uzantı kabul edilir', () {
    expect(
      normalizeEmail('  Dr.Ayse+1@Klinik.Dental '),
      'dr.ayse+1@klinik.dental',
    );
    expect(normalizeEmail('a@b'), isNull);
  });

  test('normalizeContact türü ayırır', () {
    expect(isEmailContact(normalizeContact('A@b.co')!), isTrue);
    expect(isEmailContact(normalizeContact('5551234567')!), isFalse);
    expect(normalizeContact('merhaba'), isNull);
  });
}
