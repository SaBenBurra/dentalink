import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/paging.dart';

/// `(created_at, id)` imleçten sonraki satırların PostgREST `or` koşulu:
/// azalan listede daha eskiler, [ascending] listede daha yeniler.
String keysetFilter(PageCursor cursor, {bool ascending = false}) {
  final op = ascending ? 'gt' : 'lt';
  final at = '"${_at(cursor)}"';
  return 'created_at.$op.$at,and(created_at.eq.$at,id.$op.${cursor.id})';
}

String _at(PageCursor cursor) => cursor.createdAt.toUtc().toIso8601String();

extension KeysetQuery<T> on PostgrestFilterBuilder<T> {
  /// İmleçten sonraki satırlar. Fazladan `created_at` sınırı Postgres'in
  /// indeksi imleçten başlatmasını sağlar; `or` tek başına indeks koşulu olmaz
  /// ve derin sayfalarda baştan tarar.
  PostgrestFilterBuilder<T> after(PageCursor cursor, {bool ascending = false}) =>
      (ascending ? gte('created_at', _at(cursor)) : lte('created_at', _at(cursor)))
          .or(keysetFilter(cursor, ascending: ascending));

  /// En yeniden eskiye bir sayfa; [before] verilirse ondan eski satırlar.
  PostgrestTransformBuilder<T> pageBefore(PageCursor? before) =>
      (before == null ? this : after(before))
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(pageSize);
}

/// Dolu sayfanın son satırı sonraki imleçtir; eksik sayfa son sayfadır.
PageCursor? nextCursor(List<dynamic> rows) {
  if (rows.length < pageSize) return null;
  final last = rows.last as Map<String, dynamic>;
  return (
    createdAt: DateTime.parse(last['created_at'] as String),
    id: last['id'] as String,
  );
}
