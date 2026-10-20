import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/error/app_failures.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../../domain/enums/enums.dart';
import '../models/post_model.dart';
import '../models/tag_model.dart';
import '../models/user_model.dart';
import 'post_repository.dart';

/// Supabase tabanlı gönderi repository implementasyonu.
///
/// Veritabanı ilişkilerini PostgREST join'leriyle çözer:
/// - `posts` → `users` (yazar bilgisi)
/// - `posts` → `post_images` (vaka görselleri)
/// - `posts` → `post_tags` → `tags` (etiketler)
/// - `posts` → `likes` (beğeni durumu, mevcut kullanıcı filtresiyle)
/// - `posts` → `bookmarks` (kaydetme durumu, mevcut kullanıcı filtresiyle)
///
/// Sayaçlar (like_count, comment_count, vb.) Supabase trigger'ları
/// tarafından otomatik güncellenir; bu sınıf sayaç aritmetiği yapmaz.
class SupabasePostRepository implements PostRepository {
  final SupabaseClient _client;

  /// Post, yazar, görseller, etiketler ve oturum açan kullanıcıya ait
  /// like/bookmark durumlarını çeken ortak (DRY) PostgREST seçimi.
  static const _fullPostSelect = '''
    *,
    users!posts_user_id_fkey(*),
    post_images(id, image_url, sort_order),
    post_tags(tags(id, name, slug, usage_count)),
    likes(id, user_id),
    bookmarks(id, user_id)
  ''';

  SupabasePostRepository(SupabaseClient client) : _client = client;

  /// Mevcut oturumdaki kullanıcı kimliği.
  String get _currentUserId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Oturum açılmamış.');
    return uid;
  }

  /// Supabase'den dönen JSON haritasını uygun [PostModel] alt sınıfına
  /// (`CasePostModel` veya `QuestionPostModel`) dönüştürür.
  PostModel _mapRowToPost(Map<String, dynamic> row) {
    final uid = _currentUserId;

    // --- Yazar ---
    final author = UserModel.fromJson(row['users'] as Map<String, dynamic>);

    // --- Görseller ---
    final rawImages = row['post_images'] as List<dynamic>? ?? [];
    // sort_order'a göre sırala
    rawImages.sort((a, b) =>
        (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0));
    // image_url bucket içi yol tutar (migration 015).
    final bucket = rawImages.isEmpty ? null : _client.storage.from('post-images');
    final imageUrls = [
      for (final e in rawImages) bucket!.getPublicUrl(e['image_url'] as String),
    ];

    // --- Etiketler ---
    final rawTags = row['post_tags'] as List<dynamic>? ?? [];
    final tags = rawTags.map((pt) {
      final t = pt['tags'] as Map<String, dynamic>;
      return TagModel(
        id: t['id'] as String,
        name: t['name'] as String,
        slug: t['slug'] as String,
        usageCount: t['usage_count'] as int? ?? 0,
      );
    }).toList();

    // --- Beğeni / Kaydetme durumu ---
    final rawLikes = row['likes'] as List<dynamic>? ?? [];
    final isLiked = rawLikes.any((l) => l['user_id'] == uid);

    final rawBookmarks = row['bookmarks'] as List<dynamic>? ?? [];
    final isBookmarked = rawBookmarks.any((b) => b['user_id'] == uid);

    // --- Ortak alanlar ---
    final type = PostType.fromDbValue(row['type'] as String);
    final createdAt = DateTime.parse(row['created_at'] as String);
    final updatedAt = DateTime.parse(row['updated_at'] as String);

    switch (type) {
      case PostType.casePost:
        return CasePostModel(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          title: row['title'] as String,
          content: row['content'] as String,
          branch: DentalBranch.tryFromDbValue(row['branch'] as String?),
          imageUrls: imageUrls,
          tags: tags,
          likeCount: row['like_count'] as int? ?? 0,
          commentCount: row['comment_count'] as int? ?? 0,
          bookmarkCount: row['bookmark_count'] as int? ?? 0,
          viewCount: row['view_count'] as int? ?? 0,
          isLiked: isLiked,
          isBookmarked: isBookmarked,
          createdAt: createdAt,
          updatedAt: updatedAt,
          author: author,
        );
      case PostType.question:
        return QuestionPostModel(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          title: row['title'] as String,
          content: row['content'] as String,
          isSolved: row['is_solved'] as bool? ?? false,
          tags: tags,
          likeCount: row['like_count'] as int? ?? 0,
          commentCount: row['comment_count'] as int? ?? 0,
          bookmarkCount: row['bookmark_count'] as int? ?? 0,
          viewCount: row['view_count'] as int? ?? 0,
          isLiked: isLiked,
          isBookmarked: isBookmarked,
          createdAt: createdAt,
          updatedAt: updatedAt,
          author: author,
        );
    }
  }

  /// İçerisinde oturum açan kullanıcının like ve bookmark durumlarını filtreleyen,
  /// tekrarlayan (DRY) temel PostgREST sorgusunu döndürür.
  /// (Tüm Likes/Bookmarks'ları çekmeyerek N+1 performans sorununu çözer)
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _basePostQuery() {
    final uid = _currentUserId;
    return _client
        .from('posts')
        .select(_fullPostSelect)
        .eq('likes.user_id', uid)
        .eq('bookmarks.user_id', uid);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  IFeedRepository
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<PostModel>> getFeed({bool chronological = true}) async {
    final response = await _basePostQuery()
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List<dynamic>)
        .map((e) => _mapRowToPost(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PostModel> getPostById(String id) => guardSupabase(() async {
    final response = await _basePostQuery()
        .eq('id', id)
        .single();

    return _mapRowToPost(response);
  });

  @override
  Future<List<PostModel>> getPostsByUser(String userId) async {
    final response = await _basePostQuery()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => _mapRowToPost(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ISearchRepository
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<PostModel>> searchPosts(
    String query, {
    DentalBranch? branch,
    PostType? type,
  }) async {
    // Boş sorgu — boş sonuç döndür.
    final q = query.trim();
    if (q.isEmpty) return [];

    var request = _basePostQuery();

    // Full-text search: `search_vector` sütunu üzerinde `plainto_tsquery`
    // kullanılır. 'turkish' konfigürasyonu ile kelime kökleri (stemming) desteklenir.
    request = request.textSearch('search_vector', q, type: TextSearchType.plain, config: 'turkish');

    if (branch != null) {
      request = request.eq('branch', branch.dbValue);
    }
    if (type != null) {
      request = request.eq('type', type.dbValue);
    }

    final response = await request
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List<dynamic>)
        .map((e) => _mapRowToPost(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  IBookmarkRepository
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<PostModel>> getBookmarkedPosts() async {
    final uid = _currentUserId;

    // Bookmark'lanmış post id'lerini çek, ardından postları getir.
    final bookmarkRows = await _client
        .from('bookmarks')
        .select('post_id')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final postIds = (bookmarkRows as List<dynamic>)
        .map((e) => e['post_id'] as String)
        .toList();

    if (postIds.isEmpty) return [];

    final response = await _basePostQuery()
        .inFilter('id', postIds);

    final posts = (response as List<dynamic>)
        .map((e) => _mapRowToPost(e as Map<String, dynamic>))
        .toList();

    // Bookmark sırasını koru (en son kaydedilen üstte).
    final idOrder = {for (var i = 0; i < postIds.length; i++) postIds[i]: i};
    posts.sort((a, b) => (idOrder[a.id] ?? 0).compareTo(idOrder[b.id] ?? 0));

    return posts;
  }

  @override
  Future<PostModel> bookmarkPost(String postId) => guardSupabase(() async {
    final uid = _currentUserId;

    try {
      await _client.from('bookmarks').insert({
        'user_id': uid,
        'post_id': postId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') {
        rethrow;
      }
    }

    // Güncel post'u yeniden çek (sayaç trigger tarafından güncellenir).
    return getPostById(postId);
  });

  @override
  Future<PostModel> unbookmarkPost(String postId) => guardSupabase(() async {
    final uid = _currentUserId;

    await _client
        .from('bookmarks')
        .delete()
        .eq('user_id', uid)
        .eq('post_id', postId);

    return getPostById(postId);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  IPostActionRepository
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<PostModel> likePost(String postId) => guardSupabase(() async {
    final uid = _currentUserId;

    try {
      await _client.from('likes').insert({
        'user_id': uid,
        'post_id': postId,
      });
    } on PostgrestException catch (e) {
      // 23505 is the PostgreSQL error code for unique_violation
      if (e.code != '23505') {
        rethrow;
      }
    }

    return getPostById(postId);
  });

  @override
  Future<PostModel> unlikePost(String postId) => guardSupabase(() async {
    final uid = _currentUserId;

    await _client
        .from('likes')
        .delete()
        .eq('user_id', uid)
        .eq('post_id', postId);

    return getPostById(postId);
  });

  @override
  Future<void> incrementViewCount(String postId) async {
    // Race condition önlemek için RPC fonksiyonu kullanıyoruz.
    await _client.rpc('increment_view_count', params: {'p_post_id': postId});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ICreatePostRepository
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<PostModel> createCase({
    required String title,
    required String content,
    required DentalBranch branch,
    required List<File> imageFiles,
    required List<String> tags,
  }) => guardSupabase(() async {
    final uid = _currentUserId;
    // Görseller önce; post, görsel kayıtları ve etiketler tek RPC'de (migration 015).
    final paths = await _uploadImages(uid, imageFiles);
    try {
      return await _createPost(
        type: PostType.casePost,
        title: title,
        content: content,
        branch: branch,
        imagePaths: paths,
        tags: tags,
      );
    } catch (_) {
      await _removeImages(paths);
      rethrow;
    }
  });

  @override
  Future<PostModel> createQuestion({
    required String title,
    required String content,
    required List<String> tags,
  }) => guardSupabase(() => _createPost(
        type: PostType.question,
        title: title,
        content: content,
        tags: tags,
      ));

  Future<PostModel> _createPost({
    required PostType type,
    required String title,
    required String content,
    DentalBranch? branch,
    List<String> imagePaths = const [],
    required List<String> tags,
  }) async {
    final postId = await _client.rpc('create_post', params: {
      'p_type': type.dbValue,
      'p_title': title,
      'p_content': content,
      'p_branch': branch?.dbValue,
      'p_image_paths': imagePaths,
      'p_tags': _tagsPayload(tags),
    }) as String;
    return getPostById(postId);
  }

  @override
  Future<void> deletePost(String postId) => guardSupabase(() async {
    // 1) Görsel yollarını, satır CASCADE ile silinmeden önce al.
    final images = await _client
        .from('post_images')
        .select('image_url')
        .eq('post_id', postId);

    // 2) Önce satırı sil. RLS sahibi olmayanın silmesini hata vermeden 0 satıra
    // düşürdüğü için silinen satır döndürülüp kontrol edilir.
    final deleted = await _client
        .from('posts')
        .delete()
        .eq('id', postId)
        .select('id');
    if (deleted.isEmpty) throw const PermissionDeniedFailure();

    // 3) En son dosyalar: burada hata olsa bile post zaten silinmiştir,
    // en kötü ihtimalle yetim dosya kalır (veri kaybı değil).
    await _removeImages([for (final e in images) e['image_url'] as String]);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  PRİVATE YARDIMCILAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Görselleri `post-images` bucket'ına kullanıcının klasörüne yükler,
  /// bucket içi yolları döndürür. Biri bile başarısız olursa yüklenenler
  /// silinir ve hata fırlatılır.
  Future<List<String>> _uploadImages(String userId, List<File> imageFiles) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final paths = [
      for (final (i, f) in imageFiles.indexed)
        '$userId/${stamp}_$i.${f.path.split('.').last.toLowerCase()}',
    ];
    try {
      await Future.wait([
        for (final (i, f) in imageFiles.indexed)
          _client.storage.from('post-images').upload(
                paths[i],
                f,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
              ),
      ]);
    } catch (_) {
      // remove(), olmayan yolları sessizce atlar.
      await _removeImages(paths);
      rethrow;
    }
    return paths;
  }

  /// En iyi çaba: hata olursa en kötü ihtimalle yetim dosya kalır.
  Future<void> _removeImages(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from('post-images').remove(paths);
    } catch (e) {
      debugPrint('post-images silinemedi: $e');
    }
  }

  /// slug → ilk görülen isim. Boş slug'lar ("???") ve tekrarlar atlanır.
  List<Map<String, String>> _tagsPayload(List<String> tagNames) {
    final bySlug = <String, String>{};
    for (final name in tagNames) {
      final trimmedName = name.trim();
      final slug = _slugify(trimmedName);
      if (slug.isNotEmpty) bySlug.putIfAbsent(slug, () => trimmedName);
    }
    return [for (final e in bySlug.entries) {'name': e.value, 'slug': e.key}];
  }

  /// Türkçe uyumlu basit slug oluşturma.
  ///
  /// Türkçe karakterleri ASCII eşdeğerlerine çevirir ve URL-güvenli hale getirir.
  String _slugify(String input) {
    const trMap = {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u',
    };

    var slug = input.toLowerCase();
    trMap.forEach((key, value) => slug = slug.replaceAll(key, value));
    slug = slug.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    slug = slug.replaceAll(RegExp(r'[\s-]+'), '-');
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    return slug;
  }
}
