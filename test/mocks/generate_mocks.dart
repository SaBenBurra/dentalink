import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@GenerateNiceMocks([
  MockSpec<SupabaseClient>(),
  MockSpec<GoTrueClient>(),
  MockSpec<SupabaseQueryBuilder>(),
  MockSpec<PostgrestFilterBuilder<List<Map<String, dynamic>>>>(as: #MockPostgrestFilterBuilderList),
  MockSpec<PostgrestFilterBuilder<Map<String, dynamic>>>(as: #MockPostgrestFilterBuilderMap),
  MockSpec<PostgrestTransformBuilder<List<Map<String, dynamic>>>>(as: #MockPostgrestTransformBuilderList),
  MockSpec<PostgrestTransformBuilder<Map<String, dynamic>>>(as: #MockPostgrestTransformBuilderMap),
  MockSpec<SupabaseStorageClient>(),
  MockSpec<StorageFileApi>(),
  MockSpec<User>(),
])
void main() {}
