import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/badge_model.dart';
import 'package:dentlink/data/models/conversation_model.dart';
import 'package:dentlink/data/models/message_model.dart';
import 'package:dentlink/data/models/notification_model.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/auth_repository.dart';
import 'package:dentlink/data/repositories/follow_repository.dart';
import 'package:dentlink/data/repositories/message_repository.dart';
import 'package:dentlink/data/repositories/notification_repository.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/data/repositories/user_repository.dart';
import 'package:dentlink/data/models/comment_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/repositories/comment_repository.dart';
import 'package:dentlink/providers/connectivity_provider.dart';
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
List<Override> fakeRepositoryOverrides({
  AuthRepository? auth,
  List<PostModel>? feed,
}) {
  final posts = _FakePostRepository(feed ?? [seedCase]);
  return [
    supabaseClientProvider.overrideWith(
      (_) => throw StateError('Testte gerçek Supabase istemcisi kullanılmamalı'),
    ),
    authRepositoryProvider.overrideWithValue(auth ?? MockAuthForTest()),
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
    connectivityProvider.overrideWith((_) => Stream.value([ConnectivityResult.wifi])),
  ];
}

class _FakePostRepository implements PostRepository {
  _FakePostRepository(this._feed);

  final List<PostModel> _feed;
  final _created = <String, PostModel>{};

  @override
  Future<PostModel> createQuestion({
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    final post = QuestionPostModel(
      id: 'q${_created.length + 1}',
      userId: 'mock_test_user_id',
      title: title,
      content: content,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      author: otherUser,
    );
    return _created[post.id] = post;
  }

  @override
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) async =>
      (items: _feed, next: null);

  @override
  Future<PostModel> getPostById(String id) async =>
      id == seedCase.id ? seedCase : _created[id] ?? (throw const NotFoundFailure());

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
  Future<PageResult<CommentModel>> getComments(String postId,
          {PageCursor? after}) async =>
      (items: <CommentModel>[], next: null);

  @override
  Future<CommentModel> addComment(String postId, String content) async =>
      CommentModel(
        id: 'c1',
        postId: postId,
        userId: 'me',
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

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
