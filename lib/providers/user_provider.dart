import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/badge_model.dart';
import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';
import 'following_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User Profile Provider
// ─────────────────────────────────────────────────────────────────────────────

class UserProfileNotifier
    extends AutoDisposeFamilyAsyncNotifier<UserModel, String> {
  @override
  Future<UserModel> build(String userId) async {
    final repo = ref.read(userRepositoryProvider);

    // Profil ve takip durumunu paralel yükle.
    final (user, isFollowing) = await (
      repo.getUserById(userId),
      repo.isFollowingUser(userId),
    ).wait;

    // Takip state'ini merkezi provider'a yaz.
    // Not: Bu side-effect kasıtlıdır — profil yüklendiğinde takip
    // durumunun da hazır olması gerekir. followingStateProvider bu
    // notifier'ın yaşam döngüsünden bağımsız olduğu için rebuild
    // döngüsü oluşturmaz.
    ref.read(followingStateProvider.notifier).setFollowStatus(userId, isFollowing);

    return user;
  }

  Future<void> toggleFollow() async {
    final user = state.valueOrNull;
    if (user == null) return;

    final followingNotifier = ref.read(followingStateProvider.notifier);
    final wasFollowing = followingNotifier.isFollowing(user.id);

    // Optimistic update — takipçi sayısını anında güncelle.
    state = AsyncData(
      user.copyWith(
        followersCount: wasFollowing
            ? (user.followersCount - 1).clamp(0, 999999)
            : user.followersCount + 1,
      ),
    );

    try {
      await followingNotifier.toggleFollow(user.id);
    } catch (_) {
      // Rollback — eski state'e dön.
      state = AsyncData(user);
      rethrow;
    }
  }
}

final userProfileProvider = AsyncNotifierProvider.autoDispose
    .family<UserProfileNotifier, UserModel, String>(() {
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
