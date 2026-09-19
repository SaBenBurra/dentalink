import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/notification_model.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/data/models/user_model.dart';

void main() {
  final testActor = UserModel(
    id: 'actor-1',
    fullName: 'Bildirim Gönderen',
    username: 'actor',
    title: UserTitle.disHekimi,
    createdAt: DateTime(2024, 1, 1),
  );

  group('NotificationModel -', () {
    test('constructor sets correct defaults', () {
      final notif = NotificationModel(
        id: 'notif-1',
        type: NotificationType.like,
        actor: testActor,
        createdAt: DateTime(2024, 6, 1),
      );

      expect(notif.id, 'notif-1');
      expect(notif.type, NotificationType.like);
      expect(notif.actor.id, 'actor-1');
      expect(notif.postId, isNull);
      expect(notif.commentId, isNull);
      expect(notif.isRead, isFalse);
    });

    test('constructor with all fields', () {
      final notif = NotificationModel(
        id: 'notif-2',
        type: NotificationType.comment,
        actor: testActor,
        postId: 'post-1',
        commentId: 'comment-1',
        isRead: true,
        createdAt: DateTime(2024, 6, 1),
      );

      expect(notif.postId, 'post-1');
      expect(notif.commentId, 'comment-1');
      expect(notif.isRead, isTrue);
    });

    test('all notification types can be used', () {
      for (final type in NotificationType.values) {
        final notif = NotificationModel(
          id: 'notif-${type.name}',
          type: type,
          actor: testActor,
          createdAt: DateTime(2024),
        );
        expect(notif.type, type);
      }
    });

    test('copyWith changes specific fields', () {
      final original = NotificationModel(
        id: 'notif-1',
        type: NotificationType.follow,
        actor: testActor,
        isRead: false,
        createdAt: DateTime(2024, 6, 1),
      );

      final updated = original.copyWith(isRead: true);

      expect(updated.isRead, isTrue);
      expect(updated.id, 'notif-1');
      expect(updated.type, NotificationType.follow);
    });

    test('equality: same id means equal', () {
      final a = NotificationModel(
        id: 'n-1', type: NotificationType.like,
        actor: testActor, createdAt: DateTime(2024),
      );
      final b = NotificationModel(
        id: 'n-1', type: NotificationType.comment,
        actor: testActor, isRead: true, createdAt: DateTime(2025),
      );
      expect(a, equals(b));
    });

    test('equality: different id means not equal', () {
      final a = NotificationModel(
        id: 'n-1', type: NotificationType.like,
        actor: testActor, createdAt: DateTime(2024),
      );
      final b = NotificationModel(
        id: 'n-2', type: NotificationType.like,
        actor: testActor, createdAt: DateTime(2024),
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final notif = NotificationModel(
        id: 'n-abc', type: NotificationType.badge,
        actor: testActor, createdAt: DateTime(2024),
      );
      expect(notif.hashCode, 'n-abc'.hashCode);
    });
  });
}
