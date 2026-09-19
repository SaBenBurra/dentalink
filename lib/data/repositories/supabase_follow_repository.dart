import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'follow_repository.dart';

/// Supabase tabanlı takip repository implementasyonu.
class SupabaseFollowRepository implements FollowRepository {
  final SupabaseClient client;

  SupabaseFollowRepository({required this.client});

  @override
  Future<void> followUser(String userId) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Oturum açılmamış.');

    // Duplicate follow koruması: aynı çift tekrar eklenirse hata yerine
    // sessizce yok sayılır.
    await client.from('follows').upsert(
      {
        'follower_id': currentUserId,
        'following_id': userId,
      },
      onConflict: 'follower_id,following_id',
    );
  }

  @override
  Future<void> unfollowUser(String userId) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Oturum açılmamış.');

    await client
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('following_id', userId);
  }

  @override
  Future<bool> isFollowingUser(String userId) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final response = await client
        .from('follows')
        .select()
        .eq('follower_id', currentUserId)
        .eq('following_id', userId)
        .maybeSingle();

    return response != null;
  }

  @override
  Future<Set<String>> getFollowedUserIds(List<String> userIds) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null || userIds.isEmpty) return {};

    final response = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', currentUserId)
        .inFilter('following_id', userIds);

    return (response as List<dynamic>)
        .map((e) => e['following_id'] as String)
        .toSet();
  }

  @override
  Future<List<UserModel>> getFollowers(String userId) async {
    final response = await client
        .from('follows')
        .select('users!follows_follower_id_fkey(*)')
        .eq('following_id', userId);

    return (response as List<dynamic>)
        .map((e) => UserModel.fromJson(e['users']))
        .toList();
  }

  @override
  Future<List<UserModel>> getFollowing(String userId) async {
    final response = await client
        .from('follows')
        .select('users!follows_following_id_fkey(*)')
        .eq('follower_id', userId);

    return (response as List<dynamic>)
        .map((e) => UserModel.fromJson(e['users']))
        .toList();
  }
}
