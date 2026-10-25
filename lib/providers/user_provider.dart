import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/paging.dart';
import '../data/models/badge_model.dart';
import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';
import '../data/repositories/follow_repository.dart';
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

typedef _FollowPageFetch = Future<PageResult<UserModel>> Function(
  FollowRepository repo,
  String userId,
  PageCursor? before,
);

/// Takipçi ya da takip edilen listesi; sayfalar [loadMore] ile eklenir.
class FollowListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<UserModel>, String> {
  FollowListNotifier(this._fetch);

  final _FollowPageFetch _fetch;
  final _pager = Pager<UserModel>();

  bool get hasMore => _pager.hasMore;

  FollowRepository get _repo => ref.read(followRepositoryProvider);

  @override
  Future<List<UserModel>> build(String arg) async =>
      _pager.first(await _fetch(_repo, arg, null));

  Future<void> loadMore() => _pager.loadMore(
        (before) => _fetch(_repo, arg, before),
        (items) {
          final users = state.valueOrNull;
          if (users != null) state = AsyncData([...users, ...items]);
        },
      );
}

final followersProvider = AsyncNotifierProvider.autoDispose
    .family<FollowListNotifier, List<UserModel>, String>(
  () => FollowListNotifier((r, id, before) => r.getFollowers(id, before: before)),
);

final followingProvider = AsyncNotifierProvider.autoDispose
    .family<FollowListNotifier, List<UserModel>, String>(
  () => FollowListNotifier((r, id, before) => r.getFollowing(id, before: before)),
);

/// Profili takip edenlerden oturumdaki kullanıcının takip ettikleri.
/// Kendi profilinde ve oturumsuzken boş. Kesişim istemcide alınır
/// (bkz. `getAllFollowers` shortcut'ı).
final mutualFollowersProvider =
    AutoDisposeFutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final me = ref.watch(authProvider.select((a) => a.value?.id));
  if (me == null || me == userId) return const [];
  final repo = ref.read(followRepositoryProvider);
  final followers = await repo.getAllFollowers(userId);
  final followed =
      await repo.getFollowedUserIds([for (final u in followers) u.id]);
  return [for (final u in followers) if (followed.contains(u.id)) u];
});

// ─────────────────────────────────────────────────────────────────────────────
// User Badges Provider
// ─────────────────────────────────────────────────────────────────────────────

final userBadgesProvider =
    AutoDisposeFutureProvider.family<List<BadgeModel>, String>(
      (ref, userId) => ref.read(userRepositoryProvider).getUserBadges(userId),
    );
