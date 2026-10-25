import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// agents.md kural 10: UI metinleri ARB'den gelir (UX-12). Türkçe karakterli
/// string sabiti UI katmanında kalmışsa yakalanır (yorum ve debugPrint hariç).
void main() {
  test('lib/features, lib/shared ve router içinde sabit Türkçe metin yok', () {
    final literal = RegExp(r"""'[^'\n]*[çğıöşüÇĞİÖŞÜ][^'\n]*'""");
    const allowed = {"'Türkçe'"}; // Dil adı her dilde kendi yazımıyla gösterilir.
    final offenders = <String>[];
    for (final dir in ['lib/features', 'lib/shared', 'lib/core/router']) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//') || line.contains('debugPrint(')) continue;
          for (final m in literal.allMatches(line.split(' //').first)) {
            // Tek karakterlik sabitler (ör. 'ı' normalizasyonu) metin değil.
            if (m[0]!.length > 4 && !allowed.contains(m[0])) offenders.add('${f.path}:${i + 1} ${m[0]}');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
