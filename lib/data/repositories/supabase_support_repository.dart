import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_failures.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/support_model.dart';
import 'support_repository.dart';

class SupabaseSupportRepository implements SupportRepository {
  final SupabaseClient _client;

  SupabaseSupportRepository({required this._client});

  static const _threadSelect =
      'id, status, last_message_at, user_read_at, staff_read_at';
  static const _messageSelect =
      'id, from_staff, content, created_at, sender:users!support_messages_sender_id_fkey(full_name)';

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthRequiredFailure();
    return id;
  }

  @override
  Future<SupportThread?> getThread() => guardSupabase(() async {
    final row = await _client
        .from('support_threads')
        .select(_threadSelect)
        .eq('user_id', _uid)
        .maybeSingle();
    return row == null ? null : SupportThread.fromJson(row);
  });

  @override
  Future<List<SupportMessage>> getMessages(
    String threadId, {
    int limit = 200,
  }) => guardSupabase(() async {
    final rows = await _client
        .from('support_messages')
        .select(_messageSelect)
        .eq('thread_id', threadId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.reversed.map(SupportMessage.fromJson).toList();
  });

  @override
  Future<SupportMessage> send(
    String content, {
    SupportCategory? category,
    String? clientInfo,
  }) => guardSupabase(() async {
    final _ = _uid;
    final row = await _client.rpc(
      'send_support_message',
      params: {
        'p_content': content,
        'p_category': category?.name,
        'p_client_info': clientInfo,
      },
    );
    return SupportMessage.fromJson(row as Map<String, dynamic>);
  });

  @override
  Stream<SupportThread> watchThread(String userId) => _watch(
    channel: 'public:support_threads:user_id=$userId',
    table: 'support_threads',
    column: 'user_id',
    value: userId,
    map: (row) async => SupportThread.fromJson(row),
  );

  @override
  Stream<SupportMessage> watchMessages(String threadId) => _watch(
    channel: 'public:support_messages:thread_id=$threadId',
    table: 'support_messages',
    column: 'thread_id',
    value: threadId,
    // Payload'da personel adı yok; satırı join ile çek (iç not RLS'e takılır).
    map: (row) async {
      final full = await guardSupabase(
        () => _client
            .from('support_messages')
            .select(_messageSelect)
            .eq('id', row['id'] as String)
            .maybeSingle(),
      );
      return full == null ? null : SupportMessage.fromJson(full);
    },
  );

  Stream<T> _watch<T>({
    required String channel,
    required String table,
    required String column,
    required String value,
    required Future<T?> Function(Map<String, dynamic> row) map,
  }) {
    RealtimeChannel? ch;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        ch = _client
            .channel(channel)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: column,
                value: value,
              ),
              callback: (payload) async {
                if (payload.newRecord.isEmpty) return;
                try {
                  final item = await map(payload.newRecord);
                  if (item != null && !controller.isClosed) {
                    controller.add(item);
                  }
                } catch (e, st) {
                  if (!controller.isClosed) controller.addError(e, st);
                }
              },
            )
            .subscribe();
      },
      onCancel: () async {
        if (ch != null) await _client.removeChannel(ch!);
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> markRead(String threadId) => guardSupabase(
    () => _client.rpc('mark_support_read', params: {'p_thread_id': threadId}),
  );
}
