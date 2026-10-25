import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';

/// Feed, arama ve detay notifier'larının ortak beğeni/kaydetme mantığı.
enum PostToggle { like, bookmark }

extension PostToggleX on PostToggle {
  /// İyimser durum: alanı ters çevirir, sayacı ±1 günceller.
  PostModel flip(PostModel p) => switch (this) {
        PostToggle.like => p.copyWith(
            isLiked: !p.isLiked,
            likeCount: p.likeCount + (p.isLiked ? -1 : 1),
          ),
        PostToggle.bookmark => p.copyWith(
            isBookmarked: !p.isBookmarked,
            bookmarkCount: p.bookmarkCount + (p.isBookmarked ? -1 : 1),
          ),
      };

  /// Yalnızca bu toggle'ın alanlarını [from]'dan [into]'ya kopyalar; tüm postu
  /// değiştirmek eşzamanlı diğer toggle'ın iyimser değerini ezerdi.
  PostModel copyFields(PostModel into, PostModel from) => switch (this) {
        PostToggle.like =>
          into.copyWith(isLiked: from.isLiked, likeCount: from.likeCount),
        PostToggle.bookmark => into.copyWith(
            isBookmarked: from.isBookmarked,
            bookmarkCount: from.bookmarkCount,
          ),
      };

  Future<PostModel> _send(Ref ref, PostModel original) {
    switch (this) {
      case PostToggle.like:
        final repo = ref.read(postActionRepositoryProvider);
        return original.isLiked
            ? repo.unlikePost(original.id)
            : repo.likePost(original.id);
      case PostToggle.bookmark:
        final repo = ref.read(bookmarkRepositoryProvider);
        return original.isBookmarked
            ? repo.unbookmarkPost(original.id)
            : repo.bookmarkPost(original.id);
    }
  }
}

/// İyimser toggle: in-flight guard → anında [patch] → istek → sunucu
/// değerleriyle birleştir. Hata olursa yalnızca bu alanlar geri alınır ve hata
/// fırlatılır. Post yoksa veya aynı istek sürüyorsa null döner.
Future<PostModel?> runPostToggle(
  Ref<Object?> ref,
  Set<(String, PostToggle)> pending,
  PostToggle toggle,
  String postId, {
  required PostModel? Function() current,
  required void Function(PostModel Function(PostModel) update) patch,
}) async {
  final original = current();
  final key = (postId, toggle);
  if (original == null || !pending.add(key)) return null;

  final link = ref.keepAlive(); // ekran kapansa da sonuç/rollback yazılabilsin
  try {
    patch(toggle.flip);
    final server = await toggle._send(ref, original);
    patch((p) => toggle.copyFields(p, server));
    return server;
  } catch (_) {
    patch((p) => toggle.copyFields(p, original));
    rethrow;
  } finally {
    pending.remove(key);
    link.close();
  }
}
