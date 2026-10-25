import '../../core/utils/paging.dart';
import '../models/user_model.dart';

/// Takip sistemi arayüzü.
///
/// Tüm implementasyonlar (Supabase, Mock) bu sözleşmeye uymalıdır.
abstract class FollowRepository {
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

  /// Kullanıcının takipçileri, en son takip eden önce; [before] ile sonraki sayfa.
  Future<PageResult<UserModel>> getFollowers(String userId, {PageCursor? before});

  /// Sayfasız tüm takipçiler; yalnızca ortak takipçi hesabı için.
  Future<List<UserModel>> getAllFollowers(String userId);

  /// Kullanıcının takip ettikleri, en son takip edilen önce; [before] ile sonraki sayfa.
  Future<PageResult<UserModel>> getFollowing(String userId, {PageCursor? before});
}
