import 'dart:io';

import '../models/badge_model.dart';
import '../../domain/enums/enums.dart';
import '../models/user_model.dart';

/// Kullanıcı repository arayüzü.
///
/// Tüm implementasyonlar (Supabase, Mock) bu sözleşmeye uymalıdır.
abstract class UserRepository {
  /// ID'ye göre kullanıcı profilini getirir.
  ///
  /// Kullanıcı bulunamazsa exception fırlatır.
  Future<UserModel> getUserById(String id);

  /// İsim, unvan veya üniversiteye göre kullanıcı arar.
  ///
  /// Sonuç bulunamazsa boş liste döner, exception fırlatmaz.
  Future<List<UserModel>> searchUsers(String query);

  /// Bir kullanıcıyı takip eder.
  ///
  /// Kullanıcı zaten takip ediliyorsa sessizce yok sayılır
  /// (idempotent davranış).
  Future<void> followUser(String userId);

  /// Bir kullanıcının takibini bırakır.
  ///
  /// Kullanıcı zaten takip edilmiyorsa sessizce yok sayılır.
  Future<void> unfollowUser(String userId);

  /// Mevcut oturumdaki kullanıcının belirtilen kullanıcıyı takip edip
  /// etmediğini kontrol eder.
  ///
  /// Oturum yoksa `false` döner.
  Future<bool> isFollowingUser(String userId);

  /// Verilen kullanıcı ID listesinden hangilerinin takip edildiğini
  /// döndürür. Toplu sorgular için N+1 sorgu sorununu önler.
  ///
  /// Boş liste verilirse boş set döner.
  Future<Set<String>> getFollowedUserIds(List<String> userIds);

  /// Kullanıcının takipçi listesini getirir.
  Future<List<UserModel>> getFollowers(String userId);

  /// Kullanıcının takip ettiği kişi listesini getirir.
  Future<List<UserModel>> getFollowing(String userId);

  /// Kullanıcının kazandığı rozetleri getirir.
  Future<List<BadgeModel>> getUserBadges(String userId);

  /// Profil bilgilerini günceller.
  ///
  /// Sadece `null` olmayan parametreler güncellenir.
  /// Bir alanı `null`'a sıfırlamak bu interface ile desteklenmez.
  Future<void> updateProfile(
    String userId, {
    String? fullName,
    UserTitle? title,
    String? bio,
    String? university,
    String? city,
    int? experienceYears,
    String? workplace,
  });

  /// Kullanıcı avatarını yükler ve yeni public URL'yi döndürür.
  ///
  /// Eski avatar dosyası otomatik olarak silinmez (storage upsert ile
  /// aynı path'e yazıldığında üzerine yazılır).
  Future<String> uploadAvatar(String userId, File imageFile);
}
