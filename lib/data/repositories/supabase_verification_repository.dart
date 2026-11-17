import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_failures.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/verification_model.dart';
import 'verification_repository.dart';

class SupabaseVerificationRepository implements VerificationRepository {
  final SupabaseClient _client;

  SupabaseVerificationRepository({required this._client});

  static const bucket = 'verification-docs';

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthRequiredFailure();
    return id;
  }

  @override
  Future<VerificationRequest?> getLatest() => guardSupabase(() async {
    final row = await _client
        .from('verification_requests')
        .select('id, status, reason, created_at, reviewed_at')
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : VerificationRequest.fromJson(row);
  });

  @override
  Future<VerificationRequest> submit(
    Uint8List bytes,
    VerificationDocType type, {
    bool pdf = false,
  }) => guardSupabase(() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$_uid/${type.dbValue}_$stamp.${pdf ? 'pdf' : 'jpg'}';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: pdf ? 'application/pdf' : 'image/jpeg',
          ),
        );
    final String id;
    try {
      id =
          await _client.rpc(
                'submit_verification',
                params: {'p_doc_path': path, 'p_doc_type': type.dbValue},
              )
              as String;
    } catch (_) {
      // En iyi çaba: silinemezse sahipsiz medya temizliği (064/065) siler.
      try {
        await _client.storage.from(bucket).remove([path]);
      } catch (e) {
        debugPrint('doğrulama belgesi silinemedi: $e');
      }
      rethrow;
    }
    return VerificationRequest(
      id: id,
      status: VerificationStatus.pending,
      createdAt: DateTime.now(),
    );
  });
}
