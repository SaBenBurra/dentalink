import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_failures.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import 'moderation_repository.dart';

class SupabaseModerationRepository implements ModerationRepository {
  final SupabaseClient client;

  SupabaseModerationRepository({required this.client});

  String get _uid {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const AuthRequiredFailure();
    return id;
  }

  /// 23505 (zaten var) başarı sayılır; upsert reports/blocks'ta olmayan
  /// UPDATE yetkisini isterdi.
  Future<void> _insertIgnoringDuplicate(String table, Map<String, dynamic> row) async {
    try {
      await client.from(table).insert(row);
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
  }

  @override
  Future<void> report(
    ReportTarget target,
    String targetId,
    ReportReason reason, {
    String? note,
  }) => guardSupabase(() {
    final trimmed = note?.trim();
    return _insertIgnoringDuplicate('reports', {
      'reporter_id': _uid,
      'target_type': target.dbValue,
      'target_id': targetId,
      'reason': reason.dbValue,
      if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
    });
  });

  @override
  Future<void> blockUser(String userId) => guardSupabase(
    () => _insertIgnoringDuplicate('blocks', {
      'blocker_id': _uid,
      'blocked_id': userId,
    }),
  );

  @override
  Future<void> unblockUser(String userId) => guardSupabase(() async {
    await client
        .from('blocks')
        .delete()
        .eq('blocker_id', _uid)
        .eq('blocked_id', userId);
  });

  // shortcut: sayfasız; engellenen sayısı yüzleri bulursa keyset'e geç.
  @override
  Future<List<UserModel>> getBlockedUsers() => guardSupabase(() async {
    final rows = await client
        .from('blocks')
        .select('created_at, users!blocks_blocked_id_fkey(*)')
        .eq('blocker_id', _uid)
        .order('created_at', ascending: false);
    return [
      for (final r in rows)
        UserModel.fromJson(r['users'] as Map<String, dynamic>),
    ];
  });
}
