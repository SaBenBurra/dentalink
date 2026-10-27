import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_failures.dart';
import '../../core/utils/paging.dart';
import '../../core/utils/supabase_error_mapper.dart';
import 'comment_repository.dart';
import '../models/comment_model.dart';
import 'keyset.dart';

/// Supabase tabanlı yorum repository implementasyonu.
class SupabaseCommentRepository implements CommentRepository {
  final SupabaseClient _client;

  SupabaseCommentRepository({required this._client});

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthRequiredFailure();
    return id;
  }

  /// Yorum, yazar ve oturum açan kullanıcıya ait beğeni durumunu çeken PostgREST seçimi.
  static const _fullCommentSelect = '''
    id, post_id, user_id, parent_id, reply_count, content, is_best_answer, like_count, created_at, updated_at,
    author:users!comments_user_id_fkey(id, full_name, username, avatar_url, title, is_verified, created_at),
    my_likes:likes(id)
  ''';



  @override
  Future<PageResult<CommentModel>> getComments(String postId, {PageCursor? after}) => guardSupabase(() async {
    final uid = _uid;

    var query = _client
        .from('comments')
        .select(_fullCommentSelect)
        .eq('post_id', postId)
        .isFilter('parent_id', null)
        .eq('my_likes.user_id', uid);
    // En iyi cevap ilk sayfanın başında; sonraki sayfalarda tekrar gelmez.
    if (after != null) {
      query = query
          .eq('is_best_answer', false)
          .after(after, ascending: true);
    }

    final rows = await query
        .order('is_best_answer', ascending: false)
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .limit(pageSize);

    return (items: rows.map(CommentModel.fromRow).toList(), next: nextCursor(rows));
  });

  @override
  Future<PageResult<CommentModel>> getReplies(String parentId, {PageCursor? after}) => guardSupabase(() async {
    final uid = _uid;

    var query = _client
        .from('comments')
        .select(_fullCommentSelect)
        .eq('parent_id', parentId)
        .eq('my_likes.user_id', uid);
    if (after != null) query = query.after(after, ascending: true);

    final rows = await query
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .limit(pageSize);

    return (items: rows.map(CommentModel.fromRow).toList(), next: nextCursor(rows));
  });

  @override
  Future<CommentModel> addComment(String postId, String content, {String? parentId}) => guardSupabase(() async {
    final uid = _uid;

    final row = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': uid,
          'content': content,
          'parent_id': ?parentId,
        })
        .select(_fullCommentSelect)
        .single();
        
    return CommentModel.fromRow(row);
  });

  @override
  Future<void> markBestAnswer(String commentId) => guardSupabase(() async {
    await _client.rpc('mark_best_answer', params: {'p_comment_id': commentId});
  });

  @override
  Future<void> unmarkBestAnswer(String commentId) => guardSupabase(() async {
    await _client.rpc('unmark_best_answer', params: {'p_comment_id': commentId});
  });

  @override
  Future<void> likeComment(String commentId) => guardSupabase(() async {
    final uid = _uid;

    try {
      await _client.from('likes').insert({
        'user_id': uid,
        'comment_id': commentId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') {
        rethrow;
      }
    }
  });

  @override
  Future<void> unlikeComment(String commentId) => guardSupabase(() async {
    final uid = _uid;

    await _client
        .from('likes')
        .delete()
        .eq('user_id', uid)
        .eq('comment_id', commentId);
  });
}
