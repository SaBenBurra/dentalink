import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/conversation_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/domain/enums/enums.dart';

void main() {
  final otherUser = UserModel(
    id: 'user-other',
    fullName: 'Diğer Kullanıcı',
    username: 'other',
    title: UserTitle.ogrenci,
    createdAt: DateTime(2024, 1, 1),
  );

  group('ConversationModel -', () {
    test('constructor sets correct defaults', () {
      final conv = ConversationModel(
        id: 'conv-1',
        otherUser: otherUser,
      );

      expect(conv.id, 'conv-1');
      expect(conv.otherUser.id, 'user-other');
      expect(conv.lastMessageAt, isNull);
      expect(conv.lastMessagePreview, isNull);
      expect(conv.unreadCount, 0);
    });

    test('constructor with all fields', () {
      final conv = ConversationModel(
        id: 'conv-2',
        otherUser: otherUser,
        lastMessageAt: DateTime(2024, 6, 15, 14, 30),
        lastMessagePreview: 'Son mesaj önizleme...',
        unreadCount: 3,
      );

      expect(conv.lastMessageAt, DateTime(2024, 6, 15, 14, 30));
      expect(conv.lastMessagePreview, 'Son mesaj önizleme...');
      expect(conv.unreadCount, 3);
    });

    test('copyWith changes specific fields', () {
      final original = ConversationModel(
        id: 'conv-1',
        otherUser: otherUser,
        unreadCount: 5,
      );

      final updated = original.copyWith(
        unreadCount: 0,
        lastMessagePreview: 'Yeni mesaj',
      );

      expect(updated.unreadCount, 0);
      expect(updated.lastMessagePreview, 'Yeni mesaj');
      expect(updated.id, 'conv-1');
      expect(updated.otherUser.id, 'user-other');
    });

    test('equality: same id means equal', () {
      final a = ConversationModel(id: 'conv-1', otherUser: otherUser);
      final b = ConversationModel(
        id: 'conv-1', otherUser: otherUser, unreadCount: 99,
      );
      expect(a, equals(b));
    });

    test('equality: different id means not equal', () {
      final a = ConversationModel(id: 'conv-1', otherUser: otherUser);
      final b = ConversationModel(id: 'conv-2', otherUser: otherUser);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final conv = ConversationModel(id: 'conv-xyz', otherUser: otherUser);
      expect(conv.hashCode, 'conv-xyz'.hashCode);
    });
  });
}
