import 'dart:io';

import '../../core/utils/paging.dart';
import '../models/case_treatment.dart';
import '../models/enums.dart';
import '../models/post_model.dart';
import '../models/tag_model.dart';
import '../models/user_model.dart';

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
  /// [query] metni, [tags] (hepsi bulunmalı), [branch] (vakanın herhangi bir
  /// tedavisinin branşı) ve [treatment] (tedavinin slug'ı, 040) ile filtreler;
  /// [recent] ise en yeni önce. [now] sayfalar boyunca aynı kalmalı;
  /// [offset] atlanacak post sayısı.
  Future<List<PostModel>> popularPosts({
    String query = '',
    List<String> tags = const [],
    DentalBranch? branch,
    String? treatment,
    bool recent = false,
    required DateTime now,
    int offset = 0,
  });

  /// Tedaviler ve vaka sayıları (040, `list_treatments`): listedekiler ve en az
  /// bir vakada geçen kullanıcı tedavileri. [branch], [query] (ad ya da eş
  /// anlamlı) ve [slug] ile filtreler.
  Future<List<CaseTreatment>> listTreatments({
    DentalBranch? branch,
    String? query,
    String? slug,
    int limit = 50,
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

  /// Postu beğenenler, en yeni beğeni önce; engellenenler görünmez (042).
  Future<PageResult<UserModel>> getPostLikers(
    String postId, {
    PageCursor? before,
  });
  Future<void> incrementViewCount(String postId);
}

/// Yüklemeye hazır medya öğesi: görsel ya da videonun kapağı [image],
/// videoysa sıkıştırılmış mp4 [video]. Liste sırası gönderideki sıradır.
typedef MediaUpload = ({File image, File? video});

/// Gönderi oluşturma ve silme işlemleri
abstract class ICreatePostRepository {
  /// Yeni bir vaka gönderisi oluşturur.
  ///
  /// [media] Supabase Storage'a yüklenecek dosyalar, gösterim sırasıyla.
  /// Etiketler (`tags`) varsa `tags` tablosuna upsert yapılır,
  /// ardından `post_tags` junction tablosuna bağlanır. [treatments] 1–5 tedavi
  /// (040); etiketleri sunucuda posta eklenir, 5 etiket sınırına sayılmaz.
  Future<PostModel> createCase({
    required String title,
    required String content,
    required List<CaseTreatment> treatments,
    required List<MediaUpload> media,
    required List<String> tags,
  });

  /// Yeni bir forum gönderisi oluşturur; görsel ve video isteğe bağlı (en fazla 4 medya).
  Future<PostModel> createQuestion({
    required String title,
    required String content,
    List<MediaUpload> media = const [],
    required List<String> tags,
  });

  /// Başlık, içerik, tedaviler (yalnızca vaka, 1–5) ve etiketleri günceller.
  /// Medya eklenmez/silinmez; [mediaOrder] verilirse (post_images id'leri) yeniden
  /// sıralanır. Post yoksa ya da başkasınınsa [NotFoundFailure].
  Future<PostModel> updatePost({
    required String postId,
    required String title,
    required String content,
    List<CaseTreatment> treatments = const [],
    required List<String> tags,
    List<String>? mediaOrder,
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
