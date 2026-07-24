import '../models/enums.dart';
import '../models/post_model.dart';

/// Feed odaklı işlemler (Listeleme)
abstract class IFeedRepository {
  Future<List<PostModel>> getFeed({bool chronological = true});
  Future<PostModel> getPostById(String id);
  Future<List<PostModel>> getPostsByUser(String userId);
}

/// Arama işlemleri
abstract class ISearchRepository {
  Future<List<PostModel>> searchPosts(
    String query, {
    DentalBranch? branch,
    PostType? type,
  });
}

/// Kaydedilenler işlemleri
abstract class IBookmarkRepository {
  Future<List<PostModel>> getBookmarkedPosts();
  Future<PostModel> bookmarkPost(String postId);
  Future<PostModel> unbookmarkPost(String postId);
}

/// Etkileşim işlemleri
abstract class IPostActionRepository {
  Future<PostModel> likePost(String postId);
  Future<PostModel> unlikePost(String postId);
  Future<void> incrementViewCount(String postId);
}

/// Tüm gönderi işlemlerini birleştiren arayüz (Geriye dönük uyumluluk ve MockDatasource için)
abstract class PostRepository
    implements
        IFeedRepository,
        ISearchRepository,
        IBookmarkRepository,
        IPostActionRepository {}
