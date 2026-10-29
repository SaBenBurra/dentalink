import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_error_mapper.dart';
import 'push_repository.dart';

/// Tabloya doğrudan erişim yok; aynı cihazda hesap değişince token RPC ile
/// yeni kullanıcıya geçer.
class SupabasePushRepository implements PushRepository {
  final SupabaseClient _client;

  SupabasePushRepository({required this._client});

  @override
  Future<void> register(String token, String platform) => guardSupabase(() =>
      _client.rpc('register_push_token', params: {'p_token': token, 'p_platform': platform}));

  @override
  Future<void> unregister(String token) => guardSupabase(
      () => _client.rpc('unregister_push_token', params: {'p_token': token}));
}
