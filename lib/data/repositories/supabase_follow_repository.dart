import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/paging.dart';
import '../models/user_model.dart';
import 'keyset.dart';
import 'follow_repository.dart';

/// Supabase tabanlı takip repository implementasyonu.
class SupabaseFollowRepository implements FollowRepository {
  final SupabaseClient client;

  SupabaseFollowRepository({required this.client});

  @override
  Future<void> followUser(String userId) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Oturum açılmamış.');

    // Duplicate follow koruması: aynı çift tekrar eklenirse (23505) sessizce
    // yok sayılır. upsert kullanılmaz; ON CONFLICT DO UPDATE, follows üzerinde
    // olmayan UPDATE yetkisini ister.
    try {
      await client.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': userId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
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
  Future<PageResult<UserModel>> getFollowers(
    String userId, {
    PageCursor? before,
  }) => _page('users!follows_follower_id_fkey(*)', 'following_id', userId, before);

  @override
  Future<PageResult<UserModel>> getFollowing(
    String userId, {
    PageCursor? before,
  }) => _page('users!follows_following_id_fkey(*)', 'follower_id', userId, before);

  /// Takip satırları en yeni önce; imleç `follows` satırıdır.
  Future<PageResult<UserModel>> _page(
    String userEmbed,
    String column,
    String userId,
    PageCursor? before,
  ) async {
    final rows = await client
        .from('follows')
        .select('id, created_at, $userEmbed')
        .eq(column, userId)
        .pageBefore(before);

    return (
      items: [for (final row in rows) UserModel.fromJson(row['users'])],
      next: nextCursor(rows),
    );
  }

  // shortcut: tüm takipçileri tek sorguda çeker (yalnızca ortak takipçiler
  // için); büyük hesaplarda yavaşlarsa DB'de kesişim alan RPC'ye geç.
  @override
  Future<List<UserModel>> getAllFollowers(String userId) async {
    final response = await client
        .from('follows')
        .select('users!follows_follower_id_fkey(*)')
        .eq('following_id', userId);

    return (response as List<dynamic>)
        .map((e) => UserModel.fromJson(e['users']))
        .toList();
  }
}
