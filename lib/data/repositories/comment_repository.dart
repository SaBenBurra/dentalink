import '../../core/utils/paging.dart';
import '../models/comment_model.dart';

/// Yorum repository arayüzü.
abstract class CommentRepository {
  /// Bir gönderinin üst seviye yorumlarını eskiden yeniye sayfalayarak getirir;
  /// [after] verilirse sonraki sayfa. En iyi cevap varsa ilk sayfanın başındadır.
  Future<PageResult<CommentModel>> getComments(String postId, {PageCursor? after});

  /// Bir yorumun doğrudan yanıtlarını eskiden yeniye sayfalayarak getirir.
  Future<PageResult<CommentModel>> getReplies(String parentId, {PageCursor? after});

  /// Yeni yorum ekler; [parentId] verilirse o yorumun yanıtıdır.
  Future<CommentModel> addComment(String postId, String content, {String? parentId});

  /// Bir yorumu "En İyi Cevap" olarak işaretler (soru sahibi yapabilir).
  ///
  /// NOT: Önceki en iyi cevap otomatik olarak false olur. Çağıran liste
  /// yenilemekle yükümlüdür.
  Future<void> markBestAnswer(String commentId);

  /// En iyi cevap seçimini geri alır; soru çözülmemiş olur.
  Future<void> unmarkBestAnswer(String commentId);

  /// Bir yorumu beğenir.
  Future<void> likeComment(String commentId);

  /// Bir yorumdaki beğeniyi geri alır.
  Future<void> unlikeComment(String commentId);
}
