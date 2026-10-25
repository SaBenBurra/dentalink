import 'dart:io';

import '../../core/utils/paging.dart';
import '../models/enums.dart';
import '../models/post_model.dart';

/// Feed odaklı işlemler (Listeleme)
abstract class IFeedRepository {
  /// Kronolojik, en yeni önce; [before] verilirse sonraki sayfa.
  Future<PageResult<PostModel>> getFeed({PageCursor? before});
  Future<PostModel> getPostById(String id);
  Future<PageResult<PostModel>> getPostsByUser(String userId, {PageCursor? before});
}

/// Arama işlemleri
abstract class ISearchRepository {
  Future<PageResult<PostModel>> searchPosts(
    String query, {
    DentalBranch? branch,
    PostType? type,
    PageCursor? before,
  });
}

/// Kaydedilenler işlemleri
abstract class IBookmarkRepository {
  Future<PageResult<PostModel>> getBookmarkedPosts({PageCursor? before});
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

  /// Başlık, içerik, branş (yalnızca vaka) ve etiketleri günceller.
  /// Görseller düzenlenmez. Post yoksa ya da başkasınınsa [NotFoundFailure].
  Future<PostModel> updatePost({
    required String postId,
    required String title,
    required String content,
    DentalBranch? branch,
    required List<String> tags,
  });

  /// Gönderiyi siler (cascade: images, tags, likes, bookmarks, comments).
  Future<void> deletePost(String postId);
}

/// Tüm gönderi işlemlerini birleştiren arayüz (Supabase implementasyonu tek sınıfta).
abstract class PostRepository
    implements
        IFeedRepository,
        ISearchRepository,
        IBookmarkRepository,
        IPostActionRepository,
        ICreatePostRepository {}
