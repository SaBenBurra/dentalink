import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';
import 'auth_provider.dart';

/// Engellenen kullanıcılar (Ayarlar → Engellenenler). Kullanıcı değişince
/// yeniden kurulur (kural 7).
class BlockedUsersNotifier extends AutoDisposeAsyncNotifier<List<UserModel>> {
  final _pending = <String>{};

  @override
  Future<List<UserModel>> build() async {
    final uid = ref.watch(authProvider.select((a) => a.value?.id));
    if (uid == null) return const [];
    return ref.watch(moderationRepositoryProvider).getBlockedUsers();
  }

  /// İyimser: önce listeden çıkar, hata olursa eski yerine geri koy.
  Future<void> unblock(String userId) async {
    final before = state.valueOrNull;
    final index = before?.indexWhere((u) => u.id == userId) ?? -1;
    if (index < 0 || !_pending.add(userId)) return;
    final user = before![index];
    state = AsyncData([for (final u in before) if (u.id != userId) u]);
    try {
      await ref.read(moderationRepositoryProvider).unblockUser(userId);
    } catch (_) {
      final current = [...?state.valueOrNull];
      current.insert(index.clamp(0, current.length), user);
      state = AsyncData(current);
      rethrow;
    } finally {
      _pending.remove(userId);
    }
  }
}

final blockedUsersProvider =
    AsyncNotifierProvider.autoDispose<BlockedUsersNotifier, List<UserModel>>(
  BlockedUsersNotifier.new,
);
