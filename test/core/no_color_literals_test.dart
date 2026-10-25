import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// agents.md kural 11: renkler temadan (`colorScheme`) ya da `AppColors`'tan gelir (UX-16).
void main() {
  test('lib/ içinde AppColors ve tema dışında Color(0x…) sabiti yok', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') &&
            !f.path.endsWith('app_colors.dart') &&
            !f.path.contains('${Platform.pathSeparator}theme${Platform.pathSeparator}') &&
            RegExp(r'Color\(\s*0x').hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
