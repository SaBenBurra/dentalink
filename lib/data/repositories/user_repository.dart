import '../models/badge_model.dart';
import '../models/user_model.dart';

/// Kullanıcı repository arayüzü.
abstract class UserRepository {
  /// ID'ye göre kullanıcı profilini getirir.
  Future<UserModel> getUserById(String id);

  /// İsim, unvan veya üniversiteye göre kullanıcı arar.
  Future<List<UserModel>> searchUsers(String query);

  /// Bir kullanıcıyı takip eder.
  Future<void> followUser(String userId);

  /// Bir kullanıcının takibini bırakır.
  Future<void> unfollowUser(String userId);

  /// Kullanıcının takipçi listesini getirir.
  Future<List<UserModel>> getFollowers(String userId);

  /// Kullanıcının takip ettiği kişi listesini getirir.
  Future<List<UserModel>> getFollowing(String userId);

  /// Kullanıcının kazandığı rozetleri getirir.
  Future<List<BadgeModel>> getUserBadges(String userId);
}
