import '../datasources/mock_datasource.dart';
import '../models/user_model.dart';
import 'follow_repository.dart';

/// Sahte takip repository. Faz 3.5'te SupabaseFollowRepository ile swap edilir.
class MockFollowRepository implements FollowRepository {
  static const _delay = Duration(milliseconds: 350);

  // Takip edilen kullanıcı ID'lerini in-memory tutar.
  final Set<String> _followedIds = {'u3', 'u5'};

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
  Future<bool> isFollowingUser(String userId) async {
    await Future.delayed(_delay);
    return _followedIds.contains(userId);
  }

  @override
  Future<Set<String>> getFollowedUserIds(List<String> userIds) async {
    await Future.delayed(_delay);
    return _followedIds.intersection(userIds.toSet());
  }

  @override
  Future<List<UserModel>> getFollowers(String userId) async {
    await Future.delayed(_delay);
    // Mock: kendisi dışındaki ilk 4 kullanıcıyı döndür.
    return MockDatasource.users
        .where((u) => u.id != userId)
        .take(4)
        .toList();
  }

  @override
  Future<List<UserModel>> getFollowing(String userId) async {
    await Future.delayed(_delay);
    return MockDatasource.users
        .where((u) => _followedIds.contains(u.id))
        .toList();
  }
}
