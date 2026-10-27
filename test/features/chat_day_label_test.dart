import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/messaging/screens/chat_screen.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 10, 27, 0, 30);

  setUpAll(() => initializeDateFormatting());

  test('bugün ve dün, gece yarısı sınırına göre', () {
    expect(chatDayLabel(DateTime(2026, 10, 27, 0, 5), now, tr), 'Bugün');
    expect(chatDayLabel(DateTime(2026, 10, 26, 23, 55), now, tr), 'Dün');
    expect(chatDayLabel(DateTime(2026, 10, 26, 9), now, en), 'Yesterday');
  });

  test('daha eskisi tarih; yıl yalnızca farklıysa yazılır', () {
    expect(chatDayLabel(DateTime(2026, 3, 5), now, en), 'March 5');
    expect(chatDayLabel(DateTime(2026, 3, 5), now, tr), '5 Mart');
    expect(chatDayLabel(DateTime(2025, 3, 5), now, en), 'March 5, 2025');
  });
}
