import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_failures.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/badge_model.dart';
import '../../domain/enums/enums.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

/// Supabase tabanlı kullanıcı repository implementasyonu.
class SupabaseUserRepository implements UserRepository {
  final SupabaseClient client;

  SupabaseUserRepository({required this.client});

  @override
  Future<UserModel> getUserById(String id) => guardSupabase(() async {
    final response = await client
        .from('users')
        .select()
        .eq('id', id)
        .single();
    
    return UserModel.fromJson(response);
  });

  @override
  Future<List<UserModel>> searchUsers(String query) => guardSupabase(() async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final currentUserId = client.auth.currentUser?.id ?? '';

    final response = await client
        .from('users')
        .select()
        .neq('id', currentUserId)
        .textSearch('search_vector', q, type: TextSearchType.plain, config: 'turkish')
        .limit(50);

    return (response as List<dynamic>)
        .map((e) => UserModel.fromJson(e))
        .toList();
  });


  @override
  Future<List<BadgeModel>> getUserBadges(String userId) => guardSupabase(() async {
    final response = await client
        .from('user_badges')
        .select('earned_at, badges(*)')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .where((e) => e['badges'] != null)
        .map((e) {
          final badgeMap = Map<String, dynamic>.from(e['badges']);
          badgeMap['earned_at'] = e['earned_at'];
          return BadgeModel.fromJson(badgeMap);
        })
        .toList();
  });

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
  }) => guardSupabase(() async {
    if (client.auth.currentUser?.id != userId) {
      throw const ServerFailure(message: 'Yetkisiz işlem: Sadece kendi profilinizi güncelleyebilirsiniz.');
    }

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
  });

  @override
  Future<String> uploadAvatar(String userId, File imageFile) => guardSupabase(() async {
    if (client.auth.currentUser?.id != userId) {
      throw const ServerFailure(message: 'Yetkisiz işlem: Sadece kendi avatarınızı güncelleyebilirsiniz.');
    }

    // Storage leak önlemi: eski dosyaları bulup sil.
    final oldFiles = await client.storage.from('avatars').list(path: userId);
    if (oldFiles.isNotEmpty) {
      final fileNames = oldFiles.map((f) => '$userId/${f.name}').toList();
      await client.storage.from('avatars').remove(fileNames);
    }

    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from('avatars').upload(
      fileName,
      imageFile,
      fileOptions: const FileOptions(cacheControl: '3600'),
    );

    final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);

    await client.from('users').update({'avatar_url': publicUrl}).eq('id', userId);

    return publicUrl;
  });
}
