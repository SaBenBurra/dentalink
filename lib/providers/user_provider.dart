import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/badge_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/mock_user_repository.dart';
import '../data/repositories/user_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ─────────────────────────────────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// User Profile Provider
// ─────────────────────────────────────────────────────────────────────────────

class UserProfileNotifier
    extends AutoDisposeFamilyAsyncNotifier<UserModel, String> {
  @override
  Future<UserModel> build(String userId) async {
    return ref.read(userRepositoryProvider).getUserById(userId);
  }

  Future<void> toggleFollow() async {
    final user = state.valueOrNull;
    if (user == null) return;

    final repo = ref.read(userRepositoryProvider);
    if (user.isFollowing) {
      await repo.unfollowUser(user.id);
      state = AsyncData(user.copyWith(
        isFollowing: false,
        followersCount: (user.followersCount - 1).clamp(0, 999999),
      ));
    } else {
      await repo.followUser(user.id);
      state = AsyncData(user.copyWith(
        isFollowing: true,
        followersCount: user.followersCount + 1,
      ));
    }
  }
}

final userProfileProvider =
    AsyncNotifierProvider.autoDispose.family<UserProfileNotifier, UserModel, String>(() {
  return UserProfileNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// Followers / Following Providers
// ─────────────────────────────────────────────────────────────────────────────

final followersProvider =
    AutoDisposeFutureProvider.family<List<UserModel>, String>(
  (ref, userId) => ref.read(userRepositoryProvider).getFollowers(userId),
);

final followingProvider =
    AutoDisposeFutureProvider.family<List<UserModel>, String>(
  (ref, userId) => ref.read(userRepositoryProvider).getFollowing(userId),
);

// ─────────────────────────────────────────────────────────────────────────────
// User Badges Provider
// ─────────────────────────────────────────────────────────────────────────────

final userBadgesProvider =
    AutoDisposeFutureProvider.family<List<BadgeModel>, String>(
  (ref, userId) => ref.read(userRepositoryProvider).getUserBadges(userId),
);
