import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_error_mapper.dart';
import '../../domain/enums/enums.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import 'notification_repository.dart';

/// Supabase `notifications` tablosu. RLS yalnızca kullanıcının kendi
/// bildirimlerini döndürür; istemci bildirim oluşturamaz (yalnızca `is_read`).
/// Satırları migration 013'teki trigger'lar yazar.
class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository({required this._client});

  static const _select = '*, actor:users!notifications_actor_id_fkey(*)';

  @override
  Future<List<NotificationModel>> getNotifications() => guardSupabase(() async {
        final rows = await _client
            .from('notifications')
            .select(_select)
            .order('created_at', ascending: false)
            .limit(100);

        return [for (final r in rows) ?_fromRow(r)];
      });

  @override
  Stream<NotificationModel> watchNew(String userId) {
    RealtimeChannel? channel;
    late final StreamController<NotificationModel> controller;

    Future<void> emit(String id) async {
      try {
        final row = await guardSupabase(() => _client
            .from('notifications')
            .select(_select)
            .eq('id', id)
            .maybeSingle());
        final n = row == null ? null : _fromRow(row);
        if (n != null && !controller.isClosed) controller.add(n);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<NotificationModel>(
      onListen: () {
        channel = _client
            .channel('public:notifications:user_id=$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              // Payload'da actor join'i yok; tek satırı actor ile çek.
              callback: (payload) => emit(payload.newRecord['id'] as String),
            )
            .subscribe();
      },
      onCancel: () async {
        if (channel != null) await _client.removeChannel(channel!);
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Bilinmeyen tip (ileride eklenen enum değeri) eski uygulamayı çökertmesin.
  static NotificationModel? _fromRow(Map<String, dynamic> r) {
    final type = NotificationType.tryFromDbValue(r['type'] as String?);
    if (type == null) return null;
    return NotificationModel(
      id: r['id'] as String,
      type: type,
      actor: UserModel.fromJson(r['actor'] as Map<String, dynamic>),
      postId: r['post_id'] as String?,
      commentId: r['comment_id'] as String?,
      isRead: r['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }

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
