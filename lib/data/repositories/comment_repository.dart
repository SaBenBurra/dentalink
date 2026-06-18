import '../models/comment_model.dart';

/// Yorum repository arayüzü.
abstract class CommentRepository {
  /// Bir gönderinin yorumlarını getirir.
  /// En iyi cevap varsa listenin başında yer alır.
  Future<List<CommentModel>> getComments(String postId);

  /// Yeni yorum ekler.
  Future<CommentModel> addComment(String postId, String content);

  /// Bir yorumu "En İyi Cevap" olarak işaretler (soru sahibi yapabilir).
  Future<CommentModel> markBestAnswer(String commentId);

  /// Yorumu beğenir.
  Future<CommentModel> likeComment(String commentId);

  /// Yorumun beğenisini geri alır.
  Future<CommentModel> unlikeComment(String commentId);
}
