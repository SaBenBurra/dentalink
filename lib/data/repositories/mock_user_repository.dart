import '../datasources/mock_datasource.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

/// Sahte kullanıcı repository. Faz 3'te SupabaseUserRepository ile swap edilir.
class MockUserRepository implements UserRepository {
  static const _delay = Duration(milliseconds: 350);

  // Takip edilen kullanıcı ID'lerini in-memory tutar.
  final Set<String> _followedIds = {'u3', 'u5'};

  @override
  Future<UserModel> getUserById(String id) async {
    await Future.delayed(_delay);
    final user = MockDatasource.userById(id);
    return user.copyWith(isFollowing: _followedIds.contains(id));
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    await Future.delayed(_delay);
    final q = query.toLowerCase();
    return MockDatasource.users
        .where(
          (u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q) ||
              (u.university?.toLowerCase().contains(q) ?? false) ||
              u.title.displayName.toLowerCase().contains(q),
        )
        .map((u) => u.copyWith(isFollowing: _followedIds.contains(u.id)))
        .toList();
  }

  @override
  Future<void> followUser(String userId) async {
    await Future.delayed(_delay);
    _followedIds.add(userId);
  }

  @override
  Future<void> unfollowUser(String userId) async {
    await Future.delayed(_delay);
    _followedIds.remove(userId);
  }

  @override
  Future<List<UserModel>> getFollowers(String userId) async {
    await Future.delayed(_delay);
    // Mock: rastgele 4 kullanıcı döndür.
    return MockDatasource.users
        .where((u) => u.id != userId)
        .take(4)
        .map((u) => u.copyWith(isFollowing: _followedIds.contains(u.id)))
        .toList();
  }

  @override
  Future<List<UserModel>> getFollowing(String userId) async {
    await Future.delayed(_delay);
    return MockDatasource.users
        .where((u) => _followedIds.contains(u.id))
        .map((u) => u.copyWith(isFollowing: true))
        .toList();
  }

  @override
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    await Future.delayed(_delay);
    if (userId == MockDatasource.currentUserId) {
      return MockDatasource.userBadges;
    }
    // Diğer kullanıcılar için kısmi rozet listesi döndür.
    return MockDatasource.userBadges.take(1).toList();
  }
}
