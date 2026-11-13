import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_error_mapper.dart';
import '../models/app_config.dart';
import 'app_config_repository.dart';

class SupabaseAppConfigRepository implements AppConfigRepository {
  final SupabaseClient _client;

  SupabaseAppConfigRepository({required this._client});

  @override
  Future<AppConfig?> fetch(String platform) => guardSupabase(() async {
    final row = await _client
        .from('app_config')
        .select('min_supported_version, latest_version, store_url')
        .eq('platform', platform)
        .maybeSingle();
    return row == null ? null : AppConfig.fromJson(row);
  });
}
