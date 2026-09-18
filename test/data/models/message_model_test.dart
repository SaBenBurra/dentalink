import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/message_model.dart';

void main() {
  group('MessageModel -', () {
    test('constructor sets correct defaults', () {
      final msg = MessageModel(
        id: 'msg-1',
        senderId: 'user-a',
        receiverId: 'user-b',
        content: 'Merhaba',
        createdAt: DateTime(2024, 6, 1),
      );

      expect(msg.id, 'msg-1');
      expect(msg.senderId, 'user-a');
      expect(msg.receiverId, 'user-b');
      expect(msg.content, 'Merhaba');
      expect(msg.isRead, isFalse);
      expect(msg.deletedAt, isNull);
    });

    group('isDeleted -', () {
      test('returns false when deletedAt is null', () {
        final msg = MessageModel(
          id: 'msg-1',
          senderId: 'a',
          receiverId: 'b',
          content: 'test',
          createdAt: DateTime(2024),
        );

        expect(msg.isDeleted, isFalse);
      });

      test('returns true when deletedAt is set', () {
        final msg = MessageModel(
          id: 'msg-1',
          senderId: 'a',
          receiverId: 'b',
          content: 'test',
          deletedAt: DateTime(2024, 6, 15),
          createdAt: DateTime(2024),
        );

        expect(msg.isDeleted, isTrue);
      });
    });

    test('copyWith changes specific fields only', () {
      final original = MessageModel(
        id: 'msg-1',
        senderId: 'user-a',
        receiverId: 'user-b',
        content: 'Original',
        isRead: false,
        createdAt: DateTime(2024, 6, 1),
      );

      final updated = original.copyWith(isRead: true, content: 'Edited');

      expect(updated.isRead, isTrue);
      expect(updated.content, 'Edited');
      expect(updated.id, 'msg-1');
      expect(updated.senderId, 'user-a');
      expect(updated.receiverId, 'user-b');
    });

    test('equality: same id means equal', () {
      final a = MessageModel(
        id: 'msg-1', senderId: 'a', receiverId: 'b',
        content: 'X', createdAt: DateTime(2024),
      );
      final b = MessageModel(
        id: 'msg-1', senderId: 'c', receiverId: 'd',
        content: 'Y', createdAt: DateTime(2025),
      );
      expect(a, equals(b));
    });

    test('equality: different id means not equal', () {
      final a = MessageModel(
        id: 'msg-1', senderId: 'a', receiverId: 'b',
        content: 'X', createdAt: DateTime(2024),
      );
      final b = MessageModel(
        id: 'msg-2', senderId: 'a', receiverId: 'b',
        content: 'X', createdAt: DateTime(2024),
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final msg = MessageModel(
        id: 'msg-abc', senderId: 'a', receiverId: 'b',
        content: 'test', createdAt: DateTime(2024),
      );
      expect(msg.hashCode, 'msg-abc'.hashCode);
    });
  });
}
