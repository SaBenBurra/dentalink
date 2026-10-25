import 'dart:async';

import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/badge_model.dart';
import 'package:dentlink/data/models/conversation_model.dart';
import 'package:dentlink/data/models/message_model.dart';
import 'package:dentlink/data/models/notification_model.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/follow_repository.dart';
import 'package:dentlink/data/repositories/message_repository.dart';
import 'package:dentlink/data/repositories/notification_repository.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/data/repositories/user_repository.dart';
import 'package:dentlink/domain/entities/comment_entity.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/domain/repositories/comment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_auth_for_test.dart';

/// Uçtan uca akış için bellek içi veri: bir diğer kullanıcı, bir vaka, bir
/// sohbet, bir bildirim. Akışın çağırmadığı metotlar noSuchMethod ile fırlatır;
/// beklenmeyen bir backend çağrısı testte görünür olsun.
final otherUser = UserModel(
  id: 'other',
  fullName: 'Dr. Ayşe Kaya',
  username: 'aysekaya',
  title: UserTitle.endodontist,
  createdAt: DateTime(2024),
);

final seedCase = CasePostModel(
  id: 'case1',
  userId: otherUser.id,
  title: 'Alt molar kanal tedavisi',
  content: 'Dört kanallı alt molar, kalsifiye mezyal kanallar.',
  branch: DentalBranch.endodonti,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  author: otherUser,
);

final _conversation = ConversationModel(
  id: 'conv1',
  otherUser: otherUser,
  lastMessageAt: DateTime(2024),
  lastMessagePreview: 'Merhaba',
);

/// ProviderScope'a verilecek override'ların tamamı.
List<Override> fakeRepositoryOverrides() {
  final posts = _FakePostRepository();
  return [
    supabaseClientProvider.overrideWith(
      (_) => throw StateError('Testte gerçek Supabase istemcisi kullanılmamalı'),
    ),
    authRepositoryProvider.overrideWithValue(MockAuthForTest()),
    feedRepositoryProvider.overrideWithValue(posts),
    bookmarkRepositoryProvider.overrideWithValue(posts),
    searchRepositoryProvider.overrideWithValue(posts),
    postActionRepositoryProvider.overrideWithValue(posts),
    createPostRepositoryProvider.overrideWithValue(posts),
    commentRepositoryProvider.overrideWithValue(_FakeCommentRepository()),
    messageRepositoryProvider.overrideWithValue(_FakeMessageRepository()),
    notificationRepositoryProvider.overrideWithValue(_FakeNotificationRepository()),
    userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
    followRepositoryProvider.overrideWithValue(_FakeFollowRepository()),
  ];
}

class _FakePostRepository implements PostRepository {
  @override
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) async =>
      (items: [seedCase], next: null);

  @override
  Future<PostModel> getPostById(String id) async =>
      id == seedCase.id ? seedCase : throw const NotFoundFailure();

  @override
  Future<PageResult<PostModel>> getPostsByUser(String userId,
          {PageCursor? before}) async =>
      (items: userId == otherUser.id ? [seedCase] : <PostModel>[], next: null);

  @override
  Future<PageResult<PostModel>> getBookmarkedPosts({PageCursor? before}) async =>
      (items: <PostModel>[], next: null);

  @override
  Future<void> incrementViewCount(String postId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCommentRepository implements CommentRepository {
  @override
  Future<PageResult<CommentEntity>> getComments(String postId,
          {PageCursor? after}) async =>
      (items: <CommentEntity>[], next: null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMessageRepository implements MessageRepository {
  @override
  Future<List<ConversationModel>> getConversations() async => [_conversation];

  @override
  Future<PageResult<MessageModel>> getMessages(String conversationId,
          {PageCursor? before}) async =>
      (items: [
        MessageModel(
          id: 'm1',
          senderId: otherUser.id,
          receiverId: 'mock_test_user_id',
          content: 'Merhaba',
          isRead: true,
          createdAt: DateTime(2024),
        ),
      ], next: null);

  @override
  Stream<MessageModel> watchMessages(String conversationId) => const Stream.empty();

  @override
  Stream<ConversationModel> watchConversations(String userId) => const Stream.empty();

  @override
  Future<void> markMessagesAsRead(String conversationId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationModel>> getNotifications() async => [
        NotificationModel(
          id: 'n1',
          type: NotificationType.follow,
          actor: otherUser,
          createdAt: DateTime(2024),
        ),
      ];

  @override
  Stream<NotificationModel> watchNew(String userId) => const Stream.empty();

  @override
  Future<int> getUnreadCount() async => 1;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(String notificationId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserModel> getUserById(String id) async =>
      id == otherUser.id ? otherUser : throw const NotFoundFailure();

  @override
  Future<List<UserModel>> searchUsers(String query) async => [otherUser];

  @override
  Future<List<BadgeModel>> getUserBadges(String userId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFollowRepository implements FollowRepository {
  @override
  Future<bool> isFollowingUser(String userId) async => false;

  @override
  Future<Set<String>> getFollowedUserIds(List<String> userIds) async => {};

  @override
  Future<PageResult<UserModel>> getFollowers(String userId,
          {PageCursor? before}) async =>
      (items: userId == otherUser.id ? <UserModel>[] : [otherUser], next: null);

  @override
  Future<MutualFollowers> getMutualFollowers(String userId, {int limit = 3}) async =>
      (users: <UserModel>[], total: 0);

  @override
  Future<PageResult<UserModel>> getFollowing(String userId,
          {PageCursor? before}) async =>
      (items: <UserModel>[], next: null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
