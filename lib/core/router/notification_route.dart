import '../../data/models/enums.dart';

/// Bildirime dokununca açılacak rota; bildirim listesi ve push ortak kullanır.
/// Gidilecek yer yoksa (ör. rozet) null.
String? notificationRoute({
  required NotificationType type,
  required String actorId,
  required String actorName,
  String? actorAvatar,
  String? postId,
  String? commentId,
}) {
  if (type == NotificationType.follow) return '/profile/$actorId';
  if (type == NotificationType.message) {
    return Uri(
      path: '/chat/$actorId',
      queryParameters: {'name': actorName, 'avatar': actorAvatar ?? ''},
    ).toString();
  }
  if (postId == null || postId.isEmpty) return null;
  // Yükleme, "bulunamadı" ve hata durumlarını PostScreen gösterir.
  // Yorum, cevap, yorum beğenisi ve en iyi cevap bildirimleri yorumları açık getirir.
  final comments = commentId != null && commentId.isNotEmpty ? '?comments=1' : '';
  return '/post/$postId$comments';
}
