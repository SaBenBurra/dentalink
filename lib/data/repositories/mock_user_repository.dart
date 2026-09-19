import 'dart:io';

import '../datasources/mock_datasource.dart';
import '../models/badge_model.dart';
import '../../domain/enums/enums.dart';
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
    return MockDatasource.userById(id);
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

  @override
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    await Future.delayed(_delay);
    if (userId == MockDatasource.currentUserId) {
      return MockDatasource.userBadges;
    }
    // Diğer kullanıcılar için kısmi rozet listesi döndür.
    return MockDatasource.userBadges.take(1).toList();
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
    await Future.delayed(_delay);
  }

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async {
    await Future.delayed(_delay);
    return 'https://ui-avatars.com/api/?name=Mock+Avatar&background=random';
  }
}
