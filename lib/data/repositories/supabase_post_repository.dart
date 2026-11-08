import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/error/app_failures.dart';
import '../../core/utils/paging.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/case_treatment.dart';
import '../models/enums.dart';
import '../models/post_model.dart';
import '../models/tag_model.dart';
import '../models/user_model.dart';
import '../../core/utils/string_utils.dart';
import 'keyset.dart';
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
    post_images(id, image_url, sort_order, video_path),
    post_tags(tags(id, name, slug, usage_count)),
    post_treatments(branch, position, tags(name, slug)),
    likes(id, user_id),
    bookmarks(id, user_id)
  ''';

  SupabasePostRepository(SupabaseClient client) : _client = client;

  /// Mevcut oturumdaki kullanıcı kimliği.
  String get _currentUserId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthRequiredFailure();
    return uid;
  }

  /// Supabase'den dönen JSON haritasını uygun [PostModel] alt sınıfına
  /// (`CasePostModel` veya `QuestionPostModel`) dönüştürür.
  PostModel _mapRowToPost(
    Map<String, dynamic> row,
    Map<String, String> signedUrls,
  ) {
    final uid = _currentUserId;

    // --- Yazar ---
    final author = UserModel.fromJson(row['users'] as Map<String, dynamic>);

    // --- Medya (görsel ve video, 046) ---
    final rawMedia = [...row['post_images'] as List<dynamic>? ?? []]
      ..sort(
        (a, b) => (a['sort_order'] as int? ?? 0).compareTo(
          b['sort_order'] as int? ?? 0,
        ),
      );
    final media = [for (final e in rawMedia) ?_mediaItem(e, signedUrls)];

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
          treatments: _treatments(row),
          media: media,
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
          media: media,
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

  /// image_url bucket içi yol tutar (migration 015, videoda kapak resmi);
  /// imzalanamayan (silinmiş) görsel ya da video atlanır.
  static PostMediaItem? _mediaItem(
    Map<String, dynamic> e,
    Map<String, String> signed,
  ) {
    final url = signed[e['image_url']];
    final videoPath = e['video_path'] as String?;
    final videoUrl = videoPath == null ? null : signed[videoPath];
    if (url == null || (videoPath != null && videoUrl == null)) return null;
    return (id: e['id'] as String, url: url, videoUrl: videoUrl);
  }

  /// `post_treatments` satırları seçim sırasıyla; bilinmeyen branş atlanır.
  static List<CaseTreatment> _treatments(Map<String, dynamic> row) {
    final raw = [...row['post_treatments'] as List<dynamic>? ?? []]
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return [
      for (final t in raw)
        if (DentalBranch.tryFromDbValue(t['branch'] as String?) case final b?)
          CaseTreatment(
            slug: t['tags']['slug'] as String,
            name: t['tags']['name'] as String,
            branch: b,
          ),
    ];
  }

  /// Satırları post'a çevirir. `post-images` ve `post-videos` private
  /// (migration 020, 046, SEC-9): sayfadaki dosyalar bucket başına tek istekle imzalanır.
  Future<List<PostModel>> _mapRows(List<Map<String, dynamic>> rows) async {
    final media = [
      for (final row in rows) ...row['post_images'] as List<dynamic>? ?? [],
    ];
    final images = [for (final e in media) e['image_url'] as String];
    final videos = [
      for (final e in media)
        if (e['video_path'] case final String p) p,
    ];
    final signed = {
      ...await _sign(_imageBucket, images),
      ...await _sign(_videoBucket, videos),
    };
    return [for (final row in rows) _mapRowToPost(row, signed)];
  }

  static const _imageBucket = 'post-images';
  static const _videoBucket = 'post-videos';

  Future<Map<String, String>> _sign(String bucket, List<String> paths) async {
    if (paths.isEmpty) return const {};
    final results = await _client.storage
        .from(bucket)
        .createSignedUrlsResult(paths, signedUrlTtl.inSeconds);
    return {
      for (final r in results)
        if (r is SignedUrlSuccess) r.path: r.signedUrl,
    };
  }

  /// Uzun süre açık kalan ekranda görseller düşmesin diye 1 gün; sızan link en geç o zaman ölür.
  static const signedUrlTtl = Duration(days: 1);

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
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) =>
      guardSupabase(() async {
        return _toPage(await _basePostQuery().pageBefore(before));
      });

  @override
  Future<PostModel> getPostById(String id) => guardSupabase(() async {
    final response = await _basePostQuery().eq('id', id).single();

    return (await _mapRows([response])).single;
  });

  @override
  Future<PageResult<PostModel>> getPostsByUser(
    String userId, {
    PageCursor? before,
  }) => guardSupabase(() async {
    return _toPage(
      await _basePostQuery().eq('user_id', userId).pageBefore(before),
    );
  });

  Future<PageResult<PostModel>> _toPage(
    List<Map<String, dynamic>> rows,
  ) async => (items: await _mapRows(rows), next: nextCursor(rows));

  // ═══════════════════════════════════════════════════════════════════════════
  //  ISearchRepository
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<PostModel>> popularPosts({
    String query = '',
    List<String> tags = const [],
    DentalBranch? branch,
    String? treatment,
    bool recent = false,
    required DateTime now,
    int offset = 0,
  }) => guardSupabase(() async {
    final ids =
        (await _client.rpc(
                  'popular_post_ids',
                  params: {
                    'p_query': query.trim(),
                    'p_tags': tags,
                    'p_branch': branch?.dbValue,
                    'p_now': now.toUtc().toIso8601String(),
                    'p_limit': pageSize,
                    'p_offset': offset,
                    'p_treatment': treatment,
                    'p_recent': recent,
                  },
                )
                as List)
            .cast<String>();
    return _postsInOrder(ids);
  });

  /// RPC sırası korunur; arada silinen post atlanır.
  Future<List<PostModel>> _postsInOrder(List<String> ids) async {
    if (ids.isEmpty) return <PostModel>[];
    final rows = await _basePostQuery().inFilter('id', ids);
    final byId = {for (final r in rows) r['id'] as String: r};
    return _mapRows([for (final id in ids) ?byId[id]]);
  }

  @override
  Future<List<CaseTreatment>> listTreatments({
    DentalBranch? branch,
    String? query,
    String? slug,
    int limit = 50,
  }) => guardSupabase(() async {
    final rows =
        await _client.rpc(
              'list_treatments',
              params: {
                'p_branch': branch?.dbValue,
                'p_query': query,
                'p_slug': slug,
                'p_limit': limit,
              },
            )
            as List;
    return [
      for (final r in rows)
        if (DentalBranch.tryFromDbValue(r['branch'] as String?) case final b?)
          CaseTreatment(
            slug: r['slug'] as String,
            name: r['name'] as String,
            branch: b,
            caseCount: r['case_count'] as int,
          ),
    ];
  });

  @override
  Future<List<UserModel>> popularUsers({
    required DateTime now,
    int limit = 5,
  }) => guardSupabase(() async {
    final ids =
        (await _client.rpc(
                  'popular_user_ids',
                  params: {
                    'p_now': now.toUtc().toIso8601String(),
                    'p_limit': limit,
                  },
                )
                as List)
            .cast<String>();
    if (ids.isEmpty) return <UserModel>[];
    // RPC sırası korunur.
    final rows = await _client.from('users').select().inFilter('id', ids);
    final byId = {for (final r in rows) r['id'] as String: r};
    return [for (final id in ids) ?byId[id]].map(UserModel.fromJson).toList();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  IBookmarkRepository
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sayfa kaydedilme zamanına göre; imleç bookmark satırıdır.
  @override
  Future<PageResult<PostModel>> getBookmarkedPosts({
    PageCursor? before,
  }) => guardSupabase(() async {
    final uid = _currentUserId;

    // Bookmark'lanmış post id'lerini çek, ardından postları getir.
    final bookmarkRows = await _client
        .from('bookmarks')
        .select('id, created_at, post_id')
        .eq('user_id', uid)
        .pageBefore(before);

    final postIds = [for (final row in bookmarkRows) row['post_id'] as String];
    final next = nextCursor(bookmarkRows);
    if (postIds.isEmpty) return (items: <PostModel>[], next: next);

    final response = await _basePostQuery().inFilter('id', postIds);

    final posts = await _mapRows(response);

    // Bookmark sırasını koru (en son kaydedilen üstte).
    final idOrder = {for (var i = 0; i < postIds.length; i++) postIds[i]: i};
    posts.sort((a, b) => (idOrder[a.id] ?? 0).compareTo(idOrder[b.id] ?? 0));

    return (items: posts, next: next);
  });

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
      await _client.from('likes').insert({'user_id': uid, 'post_id': postId});
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
  Future<PageResult<UserModel>> getPostLikers(
    String postId, {
    PageCursor? before,
  }) => guardSupabase(() async {
    final rows = await _client
        .from('likes')
        .select('id, created_at, users(*)')
        .eq('post_id', postId)
        .pageBefore(before);

    return (
      items: [for (final row in rows) UserModel.fromJson(row['users'])],
      next: nextCursor(rows),
    );
  });

  @override
  Future<void> incrementViewCount(String postId) => guardSupabase(() async {
    // Race condition önlemek için RPC fonksiyonu kullanıyoruz.
    await _client.rpc('increment_view_count', params: {'p_post_id': postId});
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  ICreatePostRepository
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<PostModel> createCase({
    required String title,
    required String content,
    required List<CaseTreatment> treatments,
    required List<MediaUpload> media,
    required List<String> tags,
  }) => guardSupabase(
    () => _createWithMedia(
      type: PostType.casePost,
      title: title,
      content: content,
      treatments: treatments,
      media: media,
      tags: tags,
    ),
  );

  /// Dosyalar önce; post, medya kayıtları ve etiketler tek RPC'de (migration 015, 046).
  /// Herhangi bir adım başarısız olursa yüklenen dosyalar silinir.
  Future<PostModel> _createWithMedia({
    required PostType type,
    required String title,
    required String content,
    List<CaseTreatment> treatments = const [],
    required List<MediaUpload> media,
    required List<String> tags,
  }) async {
    final uid = _currentUserId;
    final videos = await _upload(_videoBucket, uid, [
      for (final m in media) ?m.video,
    ]);
    final List<String> images;
    try {
      // Videonun kapağı da görsellerle aynı sırada yüklenir.
      images = await _upload(_imageBucket, uid, [
        for (final m in media) m.image,
      ]);
    } catch (_) {
      await _remove(_videoBucket, videos);
      rethrow;
    }
    final videoIndex = media.indexWhere((m) => m.video != null);
    try {
      return await _createPost(
        type: type,
        title: title,
        content: content,
        treatments: treatments,
        imagePaths: images,
        videoPath: videos.firstOrNull,
        videoIndex: videoIndex < 0 ? null : videoIndex,
        tags: tags,
      );
    } catch (_) {
      await _remove(_imageBucket, images);
      await _remove(_videoBucket, videos);
      rethrow;
    }
  }

  @override
  Future<List<String>> suggestTags(String query) => guardSupabase(() async {
    final rows = await _client.rpc('suggest_tags', params: {'p_query': query});
    return (rows as List).cast<String>();
  });

  @override
  Future<PostModel> createQuestion({
    required String title,
    required String content,
    List<MediaUpload> media = const [],
    required List<String> tags,
  }) => guardSupabase(
    () => _createWithMedia(
      type: PostType.question,
      title: title,
      content: content,
      media: media,
      tags: tags,
    ),
  );

  Future<PostModel> _createPost({
    required PostType type,
    required String title,
    required String content,
    List<CaseTreatment> treatments = const [],
    List<String> imagePaths = const [],
    String? videoPath,
    int? videoIndex,
    required List<String> tags,
  }) async {
    final postId =
        await _client.rpc(
              'create_post',
              params: {
                'p_type': type.dbValue,
                'p_title': title,
                'p_content': content,
                'p_image_paths': imagePaths,
                'p_tags': _tagsPayload(tags),
                'p_treatments': [for (final t in treatments) t.toPayload()],
                'p_video_path': videoPath,
                'p_video_index': videoIndex,
              },
            )
            as String;
    return getPostById(postId);
  }

  @override
  Future<PostModel> updatePost({
    required String postId,
    required String title,
    required String content,
    List<CaseTreatment> treatments = const [],
    required List<String> tags,
    List<String>? mediaOrder,
  }) => guardSupabase(() async {
    await _client.rpc(
      'update_post',
      params: {
        'p_post_id': postId,
        'p_title': title,
        'p_content': content,
        'p_tags': _tagsPayload(tags),
        'p_treatments': [for (final t in treatments) t.toPayload()],
        'p_media_order': mediaOrder,
      },
    );
    return getPostById(postId);
  });

  @override
  Future<void> deletePost(String postId) => guardSupabase(() async {
    // 1) Dosya yollarını, satır CASCADE ile silinmeden önce al.
    final media = await _client
        .from('post_images')
        .select('image_url, video_path')
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
    await _remove(_imageBucket, [
      for (final e in media) e['image_url'] as String,
    ]);
    await _remove(_videoBucket, [
      for (final e in media)
        if (e['video_path'] case final String p) p,
    ]);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  //  PRİVATE YARDIMCILAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dosyaları [bucket] içinde kullanıcının klasörüne yükler,
  /// bucket içi yolları döndürür. Biri bile başarısız olursa yüklenenler
  /// silinir ve hata fırlatılır.
  Future<List<String>> _upload(
    String bucket,
    String userId,
    List<File> files,
  ) async {
    if (files.isEmpty) return const [];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final paths = [
      for (final (i, f) in files.indexed)
        '$userId/${stamp}_$i.${f.path.split('.').last.toLowerCase()}',
    ];
    try {
      await Future.wait([
        for (final (i, f) in files.indexed)
          _client.storage
              .from(bucket)
              .upload(
                paths[i],
                f,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              ),
      ]);
    } catch (_) {
      // remove(), olmayan yolları sessizce atlar.
      await _remove(bucket, paths);
      rethrow;
    }
    return paths;
  }

  /// En iyi çaba: hata olursa en kötü ihtimalle yetim dosya kalır.
  Future<void> _remove(String bucket, List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (e) {
      debugPrint('$bucket silinemedi: $e');
    }
  }

  /// slug → ilk görülen isim. Boş slug'lar ("???") ve tekrarlar atlanır.
  List<Map<String, String>> _tagsPayload(List<String> tagNames) {
    final bySlug = <String, String>{};
    for (final name in tagNames) {
      final trimmedName = name.trim();
      final slug = slugify(trimmedName);
      if (slug.isNotEmpty) bySlug.putIfAbsent(slug, () => trimmedName);
    }
    return [
      for (final e in bySlug.entries) {'name': e.value, 'slug': e.key},
    ];
  }
}
