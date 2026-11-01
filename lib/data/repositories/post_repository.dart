import 'dart:io';

import '../../core/utils/paging.dart';
import '../models/enums.dart';
import '../models/post_model.dart';
import '../models/tag_model.dart';

/// Feed odaklı işlemler (Listeleme)
abstract class IFeedRepository {
  /// Kronolojik, en yeni önce; [before] verilirse sonraki sayfa.
  Future<PageResult<PostModel>> getFeed({PageCursor? before});
  Future<PostModel> getPostById(String id);
  Future<PageResult<PostModel>> getPostsByUser(
    String userId, {
    PageCursor? before,
  });
}

/// Keşfet: popülerlik sırası ve popüler etiketler
abstract class ISearchRepository {
  /// Popülerlik sırasıyla (035, `post_hot_score`) en fazla [pageSize] post.
  /// [query] metni, [tags] (hepsi bulunmalı) ve [branch] ile filtreler.
  /// [now] sayfalar boyunca aynı kalmalı; [offset] atlanacak post sayısı.
  Future<List<PostModel>> popularPosts({
    String query = '',
    List<String> tags = const [],
    DentalBranch? branch,
    required DateTime now,
    int offset = 0,
  });

  /// En çok postta geçen [limit] etiket (`usageCount` = post sayısı).
  Future<List<TagModel>> popularTags({int limit = 5});
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
  /// ardından `post_tags` junction tablosuna bağlanır. Tedavi: [treatment] ([branch]'a ait)
  /// ya da "Diğer" adı [otherTreatment]; etiketi sunucuda posta zorunlu eklenir (033, 034).
  Future<PostModel> createCase({
    required String title,
    required String content,
    required DentalBranch branch,
    TreatmentType? treatment,
    String? otherTreatment,
    required List<File> imageFiles,
    required List<String> tags,
  });

  /// Yeni bir soru gönderisi oluşturur.
  Future<PostModel> createQuestion({
    required String title,
    required String content,
    required List<String> tags,
  });

  /// Başlık, içerik, branş (yalnızca vaka), tedavi türü (vakada zorunlu) ve etiketleri günceller.
  /// Görseller düzenlenmez. Post yoksa ya da başkasınınsa [NotFoundFailure].
  Future<PostModel> updatePost({
    required String postId,
    required String title,
    required String content,
    DentalBranch? branch,
    TreatmentType? treatment,
    String? otherTreatment,
    required List<String> tags,
  });

  /// Gönderiyi siler (cascade: images, tags, likes, bookmarks, comments).
  Future<void> deletePost(String postId);

  /// [query] ile eşleşen tanımlı etiketler (en fazla 8; 2 karakterden kısaysa boş).
  Future<List<String>> suggestTags(String query);
}

/// Tüm gönderi işlemlerini birleştiren arayüz (Supabase implementasyonu tek sınıfta).
abstract class PostRepository
    implements
        IFeedRepository,
        ISearchRepository,
        IBookmarkRepository,
        IPostActionRepository,
        ICreatePostRepository {}
