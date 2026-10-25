import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_model.dart';
import '../data/providers/repository_providers.dart';

/// Feed, arama ve detay notifier'larının ortak beğeni/kaydetme mantığı.
enum PostToggle { like, bookmark }

extension PostToggleX on PostToggle {
  bool isOn(PostModel p) => switch (this) {
        PostToggle.like => p.isLiked,
        PostToggle.bookmark => p.isBookmarked,
      };

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

/// Dokunuşlar bu süre kesilince sunucuya yalnızca son durum gider.
const postToggleDebounce = Duration(milliseconds: 400);

/// Bir notifier'ın post başına bekleyen toggle durumu.
class PostToggleQueue {
  /// Sunucudaki son bilinen hâl (seri dokunuşlar başlamadan önceki ya da son yanıt).
  final _confirmed = <(String, PostToggle), PostModel>{};
  final _lastTap = <(String, PostToggle), int>{};
  final _syncing = <(String, PostToggle)>{};
  int _taps = 0;
}

/// Son dokunuş kazanır: her dokunuş anında [patch] ile ters çevrilir; dokunuşlar
/// [postToggleDebounce] kadar kesilince istenen hâl sunucudakinden farklıysa
/// tek istek gider (istek sürerken gelen dokunuşlar ardından senkronlanır).
/// Hata olursa yalnızca bu alanlar sunucudaki hâle döner ve hata fırlatılır.
/// Senkronu yapan çağrı sunucu postunu döner; diğerleri ve post yoksa null.
Future<PostModel?> runPostToggle(
  Ref<Object?> ref,
  PostToggleQueue queue,
  PostToggle toggle,
  String postId, {
  required PostModel? Function() current,
  required void Function(PostModel Function(PostModel) update) patch,
}) async {
  final original = current();
  if (original == null) return null;
  final key = (postId, toggle);

  final link = ref.keepAlive(); // ekran kapansa da sonuç/rollback yazılabilsin
  try {
    queue._confirmed.putIfAbsent(key, () => original);
    patch(toggle.flip);
    final tap = queue._lastTap[key] = ++queue._taps;

    await Future<void>.delayed(postToggleDebounce);
    // Daha yeni dokunuş senkronu üstlenir; süren senkron bitince son hâli kontrol eder.
    if (queue._lastTap[key] != tap || !queue._syncing.add(key)) return null;

    try {
      PostModel? server;
      while (true) {
        final want = current();
        // base yoksa önceki senkron bu dokunuşu da kapsadı.
        final base = queue._confirmed[key];
        if (want == null || base == null || toggle.isOn(want) == toggle.isOn(base)) {
          break;
        }
        server = await toggle._send(ref, base);
        queue._confirmed[key] = server;
      }
      final last = server;
      // Çıkışta istenen hâl sunucuyla aynı; sayaç sunucudan alınır.
      if (last != null) patch((p) => toggle.copyFields(p, last));
      return last;
    } catch (_) {
      final base = queue._confirmed[key];
      if (base != null) patch((p) => toggle.copyFields(p, base));
      rethrow;
    } finally {
      queue._syncing.remove(key);
      queue._confirmed.remove(key);
    }
  } finally {
    link.close();
  }
}
