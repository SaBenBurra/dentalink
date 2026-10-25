import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;

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

    var request = client.from('users').select();
    // Oturum yokken '' uuid'e cast edilemez (DATA-20); kendini dışlama yalnızca oturumla.
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId != null) request = request.neq('id', currentUserId);

    final response = await request
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

    // updated_at DB trigger'ı (set_updated_at) tarafından yazılır.
    final updates = <String, dynamic>{};

    if (fullName != null) updates['full_name'] = fullName;
    if (title != null) updates['title'] = title.dbValue;
    if (bio != null) updates['bio'] = bio;
    if (university != null) updates['university'] = university;
    if (city != null) updates['city'] = city;
    if (experienceYears != null) updates['experience_years'] = experienceYears;
    if (workplace != null) updates['workplace'] = workplace;

    if (updates.isNotEmpty) {
      await client.from('users').update(updates).eq('id', userId);
    }
  });

  @override
  Future<String> uploadAvatar(String userId, File imageFile) => guardSupabase(() async {
    if (client.auth.currentUser?.id != userId) {
      throw const ServerFailure(message: 'Yetkisiz işlem: Sadece kendi avatarınızı güncelleyebilirsiniz.');
    }

    // Eski dosyalar yeni avatar yüklenip profile yazıldıktan SONRA silinir;
    // aksi halde yükleme başarısız olursa avatar_url silinmiş dosyayı gösterir.
    final oldFiles = await client.storage.from('avatars').list(path: userId);

    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from('avatars').upload(
      fileName,
      imageFile,
      fileOptions: const FileOptions(cacheControl: '3600'),
    );

    final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);

    await client.from('users').update({'avatar_url': publicUrl}).eq('id', userId);

    // En iyi çaba: avatar zaten değişti; silinemezse yetim dosya kalır, hata gösterilmez.
    if (oldFiles.isNotEmpty) {
      try {
        await client.storage
            .from('avatars')
            .remove([for (final f in oldFiles) '$userId/${f.name}']);
      } catch (e) {
        debugPrint('eski avatarlar silinemedi: $e');
      }
    }

    return publicUrl;
  });
}
