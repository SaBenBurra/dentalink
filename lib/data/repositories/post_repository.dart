import '../models/enums.dart';
import '../models/post_model.dart';

/// Gönderi repository arayüzü.
abstract class PostRepository {
  /// Feed gönderilerini getirir.
  /// [chronological] true ise en yeni önce, false ise algoritmik sıralama.
  Future<List<PostModel>> getFeed({bool chronological = true});

  /// ID'ye göre tek gönderi getirir.
  Future<PostModel> getPostById(String id);

  /// Belirli bir kullanıcının gönderilerini getirir.
  Future<List<PostModel>> getPostsByUser(String userId);

  /// Kaydedilmiş (bookmark) gönderileri getirir.
  Future<List<PostModel>> getBookmarkedPosts();

  /// Metin ve filtrelerle gönderi arar.
  Future<List<PostModel>> searchPosts(
    String query, {
    DentalBranch? branch,
    PostType? type,
  });

  /// Gönderiyi beğenir.
  Future<PostModel> likePost(String postId);

  /// Gönderinin beğenisini geri alır.
  Future<PostModel> unlikePost(String postId);

  /// Gönderiyi kaydeder.
  Future<PostModel> bookmarkPost(String postId);

  /// Gönderinin kaydını kaldırır.
  Future<PostModel> unbookmarkPost(String postId);

  /// Görüntülenme sayısını artırır.
  Future<void> incrementViewCount(String postId);
}
