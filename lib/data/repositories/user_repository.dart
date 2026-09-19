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
