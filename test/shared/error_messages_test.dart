import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/shared/utils/error_messages.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('görsel seçici izin reddi anlaşılır mesaja çevrilir', () {
    final tr = lookupAppLocalizations(const Locale('tr'));
    for (final code in ['camera_access_denied', 'photo_access_denied']) {
      expect(getErrorMessage(tr, PlatformException(code: code)), contains('izin'));
    }
    expect(
      getErrorMessage(tr, PlatformException(code: 'other')),
      'Beklenmeyen bir hata oluştu.',
    );
  });

  test('EN dilinde İngilizce mesaj döner (UX-12)', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(getErrorMessage(en, PlatformException(code: 'other')),
        'An unexpected error occurred.');
  });
}
