import 'dart:io';

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

/// Gönderi oluşturma ve silme işlemleri
abstract class ICreatePostRepository {
  /// Yeni bir vaka gönderisi oluşturur.
  ///
  /// [imageFiles] Supabase Storage'a yüklenecek ham dosyalar.
  /// Etiketler (`tags`) varsa `tags` tablosuna upsert yapılır,
  /// ardından `post_tags` junction tablosuna bağlanır.
  Future<PostModel> createCase({
    required String title,
    required String content,
    required DentalBranch branch,
    required List<File> imageFiles,
    required List<String> tags,
  });

  /// Yeni bir soru gönderisi oluşturur.
  Future<PostModel> createQuestion({
    required String title,
    required String content,
    required List<String> tags,
  });

  /// Gönderiyi siler (cascade: images, tags, likes, bookmarks, comments).
  Future<void> deletePost(String postId);
}

/// Tüm gönderi işlemlerini birleştiren arayüz (Geriye dönük uyumluluk ve MockDatasource için)
abstract class PostRepository
    implements
        IFeedRepository,
        ISearchRepository,
        IBookmarkRepository,
        IPostActionRepository,
        ICreatePostRepository {}
