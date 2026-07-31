import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../repositories/auth_repository.dart';
import '../repositories/supabase_auth_repository.dart';
import '../repositories/comment_repository.dart';
import '../repositories/mock_comment_repository.dart';
import '../repositories/message_repository.dart';
import '../repositories/mock_message_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/mock_notification_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/mock_post_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/mock_user_repository.dart';

// ─── Supabase ───
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Auth ───
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(client: ref.watch(supabaseClientProvider));
});

// ─── Post (ISP Segregated) ───
final _basePostRepositoryProvider = Provider<PostRepository>((ref) {
  return MockPostRepository();
});

final feedRepositoryProvider = Provider<IFeedRepository>((ref) => ref.watch(_basePostRepositoryProvider));
final bookmarkRepositoryProvider = Provider<IBookmarkRepository>((ref) => ref.watch(_basePostRepositoryProvider));
final searchRepositoryProvider = Provider<ISearchRepository>((ref) => ref.watch(_basePostRepositoryProvider));
final postActionRepositoryProvider = Provider<IPostActionRepository>((ref) => ref.watch(_basePostRepositoryProvider));

// ─── Comment ───
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return MockCommentRepository();
});

// ─── Message ───
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MockMessageRepository();
});

// ─── Notification ───
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});

// ─── User ───
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepository();
});
