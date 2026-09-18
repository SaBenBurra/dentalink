import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/repository_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Following State Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Takip durumlarını merkezi olarak yöneten notifier.
///
/// `UserModel`'den bağımsız olarak `Map<userId, bool>` şeklinde
/// takip state'ini tutar. Bu sayede aynı kullanıcının farklı
/// ekranlardaki (profil, arama, takipçi listesi) takip durumu
/// her zaman tutarlı kalır.
class FollowingStateNotifier extends StateNotifier<Map<String, bool>> {
  final Ref _ref;

  FollowingStateNotifier(this._ref) : super({});

  /// Belirli bir kullanıcının takip edilip edilmediğini döndürür.
  bool isFollowing(String userId) => state[userId] ?? false;

  /// Toplu takip durumlarını state'e yazar.
  ///
  /// Repository'den gelen kullanıcı listesi sonrası çağrılır.
  /// Mevcut state ile birleştirilir (merge), üzerine yazılmaz.
  void setFollowStatuses(Map<String, bool> statuses) {
    state = {...state, ...statuses};
  }

  /// Tek bir kullanıcının takip durumunu set eder.
  void setFollowStatus(String userId, bool following) {
    state = {...state, userId: following};
  }

  /// Takip/takip bırakma toggle işlemi.
  ///
  /// Optimistic update uygular: UI anında güncellenir, API başarısız
  /// olursa eski duruma geri dönülür (rollback).
  Future<void> toggleFollow(String userId) async {
    final repo = _ref.read(userRepositoryProvider);
    final wasFollowing = isFollowing(userId);

    // Optimistic update — UI anında güncellenir.
    state = {...state, userId: !wasFollowing};

    try {
      if (wasFollowing) {
        await repo.unfollowUser(userId);
      } else {
        await repo.followUser(userId);
      }
    } catch (_) {
      // Rollback — API başarısız olursa eski duruma dön.
      state = {...state, userId: wasFollowing};
      rethrow;
    }
  }
}

final followingStateProvider =
    StateNotifierProvider<FollowingStateNotifier, Map<String, bool>>((ref) {
  return FollowingStateNotifier(ref);
});

/// Belirli bir kullanıcının takip durumunu izlemek için
/// kullanışlı bir selector provider.
///
/// Kullanım:
/// ```dart
/// final isFollowing = ref.watch(isFollowingProvider(userId));
/// ```
final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  final state = ref.watch(followingStateProvider);
  return state[userId] ?? false;
});
