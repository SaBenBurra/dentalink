import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_failures.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';
import 'feed_provider.dart';
import 'post_toggle.dart';
import 'search_provider.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Tek Post Detay Provider
// ─────────────────────────────────────────────────────────────────────────────

class PostDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<PostModel, String> {
  @override
  Future<PostModel> build(String arg) async {
    return ref.read(feedRepositoryProvider).getPostById(arg);
  }

  final _pending = PostToggleQueue();

  void patch(PostModel Function(PostModel) update) {
    final post = state.valueOrNull;
    if (post != null) state = AsyncData(update(post));
  }

  Future<void> toggleLike() => _toggle(PostToggle.like);

  Future<void> toggleBookmark() => _toggle(PostToggle.bookmark);

  /// Post başka cihazda silinmişse ekran "bulunamadı" durumuna geçer;
  /// diğer hatalar UI'ın göstermesi için fırlatılır. Feed ve arama listesindeki
  /// aynı post yeniden çekilmeden güncellenir.
  Future<void> _toggle(PostToggle toggle) async {
    try {
      final server = await runPostToggle(
        ref,
        _pending,
        toggle,
        arg,
        current: () => state.valueOrNull,
        patch: patch,
      );
      if (server == null) return;
      PostModel sync(PostModel p) => toggle.copyFields(p, server);
      if (ref.exists(feedProvider)) {
        ref.read(feedProvider.notifier).patchPost(arg, sync);
      }
      if (ref.exists(searchProvider)) {
        ref.read(searchProvider.notifier).patchPost(arg, sync);
      }
    } on NotFoundFailure catch (e, st) {
      state = AsyncError(e, st);
      if (ref.exists(feedProvider)) ref.read(feedProvider.notifier).removePost(arg);
      if (ref.exists(searchProvider)) {
        ref.read(searchProvider.notifier).removePost(arg);
      }
    }
  }
}

final postDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PostDetailNotifier, PostModel, String>(() {
      return PostDetailNotifier();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Kullanıcı Postları Provider
// ─────────────────────────────────────────────────────────────────────────────

final userPostsProvider =
    AutoDisposeFutureProvider.family<List<PostModel>, String>((
      ref,
      userId,
    ) async {
      return ref.read(feedRepositoryProvider).getPostsByUser(userId);
    });

