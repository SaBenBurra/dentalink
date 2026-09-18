import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/badge_model.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

/// Supabase tabanlı kullanıcı repository implementasyonu.
class SupabaseUserRepository implements UserRepository {
  final SupabaseClient client;

  SupabaseUserRepository({required this.client});

  @override
  Future<UserModel> getUserById(String id) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', id)
        .single();
    
    return UserModel.fromJson(response);
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    // PostgREST filter özel karakterlerini escape et.
    final safeQuery = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    final response = await client
        .from('users')
        .select()
        .or('full_name.ilike.%$safeQuery%,username.ilike.%$safeQuery%,university.ilike.%$safeQuery%')
        .limit(50);

    return (response as List<dynamic>)
        .map((e) => UserModel.fromJson(e))
        .toList();
  }

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



  @override
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    // user_badges üzerinden badges join
    final response = await client
        .from('user_badges')
        .select('earned_at, badges(*)')
        .eq('user_id', userId);

    return (response as List<dynamic>).map((e) {
      final badgeMap = Map<String, dynamic>.from(e['badges']);
      badgeMap['earned_at'] = e['earned_at']; // earning date is on junction table
      return BadgeModel.fromJson(badgeMap);
    }).toList();
  }

  @override
  Future<void> updateProfile(
    String userId, {
    String? fullName,
    UserTitle? title,
    String? bio,
    String? university,
    String? city,
    int? experienceYears,
    String? workplace,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (title != null) updates['title'] = title.dbValue;
    if (bio != null) updates['bio'] = bio;
    if (university != null) updates['university'] = university;
    if (city != null) updates['city'] = city;
    if (experienceYears != null) updates['experience_years'] = experienceYears;
    if (workplace != null) updates['workplace'] = workplace;

    if (updates.length > 1) { // 1 is updated_at
      await client.from('users').update(updates).eq('id', userId);
    }
  }

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async {
    // SupabaseAuthRepository ile tutarlı path: $userId/avatar_xxx.ext
    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from('avatars').upload(
      fileName,
      imageFile,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );

    final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);

    await client.from('users').update({'avatar_url': publicUrl}).eq('id', userId);

    return publicUrl;
  }
}
