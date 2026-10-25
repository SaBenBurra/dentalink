import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/badge_model.dart';
import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';
import 'auth_provider.dart';
import 'following_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User Profile Provider
// ─────────────────────────────────────────────────────────────────────────────

class UserProfileNotifier
    extends AutoDisposeFamilyAsyncNotifier<UserModel, String> {
  @override
  Future<UserModel> build(String userId) async {
    final userRepo = ref.read(userRepositoryProvider);
    final followRepo = ref.read(followRepositoryProvider);

    // Profil ve takip durumunu paralel yükle.
    final (user, isFollowing) = await (
      userRepo.getUserById(userId),
      followRepo.isFollowingUser(userId),
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
      (ref, userId) => ref.read(followRepositoryProvider).getFollowers(userId),
    );

final followingProvider =
    AutoDisposeFutureProvider.family<List<UserModel>, String>(
      (ref, userId) => ref.read(followRepositoryProvider).getFollowing(userId),
    );

/// Profili takip edenlerden oturumdaki kullanıcının takip ettikleri.
/// Kendi profilinde ve oturumsuzken boş.
/// shortcut: tüm takipçi listesini çekip istemcide keser; takipçi sayfalaması
/// (Faz 2, DATA-12) gelince RPC ile DB'de kesişim al.
final mutualFollowersProvider =
    AutoDisposeFutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final me = ref.watch(authProvider.select((a) => a.value?.id));
  if (me == null || me == userId) return const [];
  final followers = await ref.watch(followersProvider(userId).future);
  final followed = await ref
      .read(followRepositoryProvider)
      .getFollowedUserIds([for (final u in followers) u.id]);
  return [for (final u in followers) if (followed.contains(u.id)) u];
});

// ─────────────────────────────────────────────────────────────────────────────
// User Badges Provider
// ─────────────────────────────────────────────────────────────────────────────

final userBadgesProvider =
    AutoDisposeFutureProvider.family<List<BadgeModel>, String>(
      (ref, userId) => ref.read(userRepositoryProvider).getUserBadges(userId),
    );
