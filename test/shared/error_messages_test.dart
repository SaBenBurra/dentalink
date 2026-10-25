import 'package:dentlink/shared/utils/error_messages.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('görsel seçici izin reddi anlaşılır mesaja çevrilir', () {
    for (final code in ['camera_access_denied', 'photo_access_denied']) {
      expect(getErrorMessage(PlatformException(code: code)), contains('izin'));
    }
    expect(
      getErrorMessage(PlatformException(code: 'other')),
      'Beklenmeyen bir hata oluştu.',
    );
  });
}
