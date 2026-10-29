import 'package:dentlink/core/router/notification_route.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/providers/push_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationRoute', () {
    String? route(NotificationType type, {String? postId, String? commentId}) =>
        notificationRoute(
          type: type,
          actorId: 'a1',
          actorName: 'Ayşe Y',
          postId: postId,
          commentId: commentId,
        );

    test('takip profili açar', () {
      expect(route(NotificationType.follow, postId: 'p1'), '/profile/a1');
    });

    test('mesaj sohbeti ad ve avatarla açar', () {
      expect(route(NotificationType.message),
          '/chat/a1?name=Ay%C5%9Fe+Y&avatar');
    });

    test('yorumlu bildirim yorumları açık getirir', () {
      expect(route(NotificationType.reply, postId: 'p1', commentId: 'c1'),
          '/post/p1?comments=1');
      expect(route(NotificationType.like, postId: 'p1'), '/post/p1');
    });

    test('postsuz bildirimde rota yok', () {
      expect(route(NotificationType.badge), isNull);
    });
  });

  group('pushRoute', () {
    test('Edge Function verisini çözer (boş string = yok)', () {
      expect(
        pushRoute({
          'type': 'best_answer',
          'actor_id': 'a1',
          'actor_name': 'X',
          'actor_avatar': '',
          'post_id': 'p1',
          'comment_id': 'c1',
        }),
        '/post/p1?comments=1',
      );
      expect(
        pushRoute({'type': 'like', 'actor_id': 'a1', 'post_id': 'p1', 'comment_id': ''}),
        '/post/p1',
      );
    });

    test('bilinmeyen tür yok sayılır', () {
      expect(pushRoute({'type': 'new_kind', 'post_id': 'p1'}), isNull);
      expect(pushRoute({}), isNull);
    });
  });
}
