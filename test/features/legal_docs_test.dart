import 'dart:io';

import 'package:dentlink/features/settings/screens/legal_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her hukuk metninin TR ve EN dosyası var, diğer diller EN\'e düşer', () {
    for (final doc in LegalDoc.values) {
      for (final lang in ['tr', 'en']) {
        final path = doc.assetPath(Locale(lang));
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      expect(doc.assetPath(const Locale('de')), endsWith('_en.txt'));
    }
  });

  test('bilinmeyen doküman adı null döner (rota /settings\'e yönlenir)', () {
    expect(LegalDoc.tryParse('kvkk'), LegalDoc.kvkk);
    expect(LegalDoc.tryParse('nope'), isNull);
    expect(LegalDoc.tryParse(null), isNull);
  });
}
