import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_failures.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/entities/comment_entity.dart';
import '../mappers/comment_mapper.dart';

/// Supabase tabanlı yorum repository implementasyonu.
class SupabaseCommentRepository implements CommentRepository {
  final SupabaseClient _client;

  SupabaseCommentRepository({required SupabaseClient client}) : _client = client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthRequiredFailure();
    return id;
  }

  /// Yorum, yazar ve oturum açan kullanıcıya ait beğeni durumunu çeken PostgREST seçimi.
  static const _fullCommentSelect = '''
    id, post_id, user_id, content, is_best_answer, like_count, created_at, updated_at,
    author:users!comments_user_id_fkey(id, full_name, username, avatar_url, title, is_verified, created_at),
    my_likes:likes(id)
  ''';



  @override
  Future<List<CommentEntity>> getComments(String postId, {int limit = 50, int offset = 0}) => guardSupabase(() async {
    final safeLimit = limit.clamp(1, 100);
    final safeOffset = offset < 0 ? 0 : offset;
    final uid = _uid;
    
    final response = await _client
        .from('comments')
        .select(_fullCommentSelect)
        .eq('post_id', postId)
        .eq('my_likes.user_id', uid)
        .order('is_best_answer', ascending: false)
        .order('created_at', ascending: true)
        .order('id', ascending: true) // Tiebreaker: Aynı milisaniyede atılan yorumlarda stabil sayfalama sağlar
        .range(safeOffset, safeOffset + safeLimit - 1);
        
    return (response as List<dynamic>)
        .map((e) => CommentMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<CommentEntity> addComment(String postId, String content) => guardSupabase(() async {

    final row = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          // 'user_id': uid, // RLS ve default auth.uid() sayesinde göndermeye gerek yok
          'content': content,
        })
        .select(_fullCommentSelect)
        .single();
        
    return CommentMapper.fromRow(row);
  });

  @override
  Future<void> markBestAnswer(String commentId) => guardSupabase(() async {
    await _client.rpc('mark_best_answer', params: {'p_comment_id': commentId});
  });

  @override
  Future<void> likeComment(String commentId) => guardSupabase(() async {
    final uid = _uid;

    await _client.from('likes').upsert(
      {'user_id': uid, 'comment_id': commentId},
      onConflict: 'user_id,comment_id',
      ignoreDuplicates: true,
    );
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
