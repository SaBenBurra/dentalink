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
    ref
        .read(followingStateProvider.notifier)
        .setFollowStatus(userId, isFollowing);

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

typedef _UserPageFetch =
    Future<PageResult<UserModel>> Function(
      Ref ref,
      String id,
      PageCursor? before,
    );

/// Takipçi, takip edilen ya da beğenen listesi; sayfalar [loadMore] ile eklenir.
class UserListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<UserModel>, String> {
  UserListNotifier(this._fetch);

  final _UserPageFetch _fetch;
  final _pager = Pager<UserModel>();

  bool get hasMore => _pager.hasMore;

  @override
  Future<List<UserModel>> build(String arg) async =>
      _pager.first(await _fetch(ref, arg, null));

  Future<void> loadMore() =>
      _pager.loadMore((before) => _fetch(ref, arg, before), (items) {
        final users = state.valueOrNull;
        if (users != null) state = AsyncData([...users, ...items]);
      });
}

final followersProvider = AsyncNotifierProvider.autoDispose
    .family<UserListNotifier, List<UserModel>, String>(
      () => UserListNotifier(
        (ref, id, before) =>
            ref.read(followRepositoryProvider).getFollowers(id, before: before),
      ),
    );

final followingProvider = AsyncNotifierProvider.autoDispose
    .family<UserListNotifier, List<UserModel>, String>(
      () => UserListNotifier(
        (ref, id, before) =>
            ref.read(followRepositoryProvider).getFollowing(id, before: before),
      ),
    );

final postLikersProvider = AsyncNotifierProvider.autoDispose
    .family<UserListNotifier, List<UserModel>, String>(
      () => UserListNotifier(
        (ref, id, before) => ref
            .read(postActionRepositoryProvider)
            .getPostLikers(id, before: before),
      ),
    );

/// Profili takip edenlerden oturumdaki kullanıcının takip ettikleri.
/// İlk birkaç kişi ve toplam; kendi profilinde ve oturumsuzken istek gitmez.
/// Hesap değişince yeniden hesaplanır.
final mutualFollowersProvider =
    AutoDisposeFutureProvider.family<MutualFollowers, String>((
      ref,
      userId,
    ) async {
      final me = ref.watch(authProvider.select((a) => a.value?.id));
      if (me == null || me == userId) return (users: <UserModel>[], total: 0);
      return ref.read(followRepositoryProvider).getMutualFollowers(userId);
    });

// ─────────────────────────────────────────────────────────────────────────────
// User Badges Provider
// ─────────────────────────────────────────────────────────────────────────────

final userBadgesProvider =
    AutoDisposeFutureProvider.family<List<BadgeModel>, String>(
      (ref, userId) => ref.read(userRepositoryProvider).getUserBadges(userId),
    );
