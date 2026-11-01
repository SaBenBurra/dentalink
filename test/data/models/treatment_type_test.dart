import 'dart:io';

import 'package:dentlink/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enum, DB tedavi listesiyle aynı (033 + promote_other_treatment)', () {
    final sql = File('supabase/migrations/033_treatment_types.sql').readAsStringSync();
    // Sonradan kaldırılan branşlar (037).
    final removed = {
      for (final f in Directory('supabase/migrations').listSync().whereType<File>())
        for (final m in RegExp(r"DELETE FROM public\.treatment_types WHERE branch = '([a-z_]+)'")
            .allMatches(f.readAsStringSync()))
          m[1],
    };
    final rows = {
      for (final m in RegExp(r"\('([a-z0-9-]+)', '([a-z_]+)'\)").allMatches(sql))
        '${m[1]}|${m[2]}',
      // Sonradan listeye alınan "diğer" tedaviler (034).
      for (final f in Directory('supabase/migrations').listSync().whereType<File>())
        for (final m in RegExp(r"promote_other_treatment\('([a-z0-9-]+)', '([a-z_]+)'\)")
            .allMatches(f.readAsStringSync()))
          '${m[1]}|${m[2]}',
    };
    rows.removeWhere((r) => removed.contains(r.split('|')[1]));
    expect(rows, {for (final t in TreatmentType.values) '${t.dbValue}|${t.branch.dbValue}'});
  });

  test('her branşın tedavi türü var; kod etiketin slug hali', () {
    for (final b in DentalBranch.values) {
      expect(TreatmentType.forBranch(b), isNotEmpty, reason: b.name);
    }
    const tr = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u'};
    for (final t in TreatmentType.values) {
      expect(t.tag.split('').map((c) => tr[c] ?? c).join(), t.dbValue);
    }
  });

  test('tryFromDbValue', () {
    expect(TreatmentType.tryFromDbValue('dis-cekimi'), TreatmentType.disCekimi);
    expect(TreatmentType.tryFromDbValue(null), isNull);
    expect(TreatmentType.tryFromDbValue('yok'), isNull);
  });
}
