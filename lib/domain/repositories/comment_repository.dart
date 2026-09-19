import '../entities/comment_entity.dart';

/// Yorum repository arayüzü (Domain Katmanı).
abstract class CommentRepository {
  /// Bir gönderinin yorumlarını sayfalayarak getirir.
  /// En iyi cevap varsa daima listenin başında yer alır.
  Future<List<CommentEntity>> getComments(String postId, {int limit = 50, int offset = 0});

  /// Yeni yorum ekler.
  Future<CommentEntity> addComment(String postId, String content);

  /// Bir yorumu "En İyi Cevap" olarak işaretler (soru sahibi yapabilir).
  ///
  /// NOT: Önceki en iyi cevap otomatik olarak false olur. Çağıran liste
  /// yenilemekle yükümlüdür.
  Future<void> markBestAnswer(String commentId);

  /// Bir yorumu beğenir.
  Future<void> likeComment(String commentId);

  /// Bir yorumdaki beğeniyi geri alır.
  Future<void> unlikeComment(String commentId);
}
