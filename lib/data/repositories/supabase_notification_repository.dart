import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_error_mapper.dart';
import '../../domain/enums/enums.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'notification_repository.dart';

/// Supabase `notifications` tablosu. RLS yalnızca kullanıcının kendi
/// bildirimlerini döndürür; istemci bildirim oluşturamaz (yalnızca `is_read`).
///
/// shortcut: bildirim üreten trigger'lar ve realtime henüz yok; liste şimdilik
/// boş gelir (ROADMAP Faz 1 — DATA-5).
class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository({required SupabaseClient client})
      : _client = client;

  @override
  Future<List<NotificationModel>> getNotifications() => guardSupabase(() async {
        final rows = await _client
            .from('notifications')
            .select('*, actor:users!notifications_actor_id_fkey(*)')
            .order('created_at', ascending: false)
            .limit(100);

        return [
          for (final r in rows)
            // Bilinmeyen tip (ileride eklenen enum değeri) eski uygulamayı çökertmesin.
            if (NotificationType.tryFromDbValue(r['type'] as String?) case final type?)
              NotificationModel(
                id: r['id'] as String,
                type: type,
                actor: UserModel.fromJson(r['actor'] as Map<String, dynamic>),
                postId: r['post_id'] as String?,
                commentId: r['comment_id'] as String?,
                isRead: r['is_read'] as bool? ?? false,
                createdAt: DateTime.parse(r['created_at'] as String),
              ),
        ];
      });

  @override
  Future<int> getUnreadCount() => guardSupabase(() async {
        return _client
            .from('notifications')
            .count(CountOption.exact)
            .eq('is_read', false);
      });

  @override
  Future<void> markAllRead() => guardSupabase(() async {
        await _client
            .from('notifications')
            .update({'is_read': true})
            .eq('is_read', false);
      });

  @override
  Future<void> markRead(String notificationId) => guardSupabase(() async {
        await _client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notificationId);
      });
}
