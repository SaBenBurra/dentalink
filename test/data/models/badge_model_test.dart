import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/badge_model.dart';

void main() {
  group('BadgeModel -', () {
    test('fromJson creates model with correct field mapping', () {
      final json = {
        'id': 'badge-1',
        'name': 'İlk Gönderi',
        'description': 'İlk gönderinizi paylaştınız!',
        'icon_url': 'star',
        'earned_at': '2024-01-15T10:30:00.000Z',
      };

      final badge = BadgeModel.fromJson(json);

      expect(badge.id, 'badge-1');
      expect(badge.name, 'İlk Gönderi');
      expect(badge.description, 'İlk gönderinizi paylaştınız!');
      expect(badge.iconName, 'star'); // icon_url → iconName mapping
      expect(badge.earnedAt, DateTime.utc(2024, 1, 15, 10, 30));
    });

    test('fromJson maps icon_url to iconName correctly', () {
      final json = {
        'id': 'badge-2',
        'name': 'Verified',
        'description': 'Doğrulanmış hesap',
        'icon_url': 'verified',
        'earned_at': '2024-06-01T00:00:00.000Z',
      };

      final badge = BadgeModel.fromJson(json);
      // icon_url alanı iconName property'sine map edilir
      expect(badge.iconName, 'verified');
    });

    test('fromJson parses earned_at as DateTime', () {
      final json = {
        'id': 'badge-3',
        'name': 'Test',
        'description': 'Desc',
        'icon_url': 'emoji_events',
        'earned_at': '2025-12-31T23:59:59.000Z',
      };

      final badge = BadgeModel.fromJson(json);
      expect(badge.earnedAt.year, 2025);
      expect(badge.earnedAt.month, 12);
      expect(badge.earnedAt.day, 31);
    });

    test('equality: same id means equal', () {
      final badge1 = BadgeModel(
        id: 'badge-1',
        name: 'Test',
        description: 'Desc',
        iconName: 'star',
        earnedAt: DateTime(2024),
      );
      final badge2 = BadgeModel(
        id: 'badge-1',
        name: 'Different Name',
        description: 'Different',
        iconName: 'check',
        earnedAt: DateTime(2025),
      );

      expect(badge1, equals(badge2));
    });

    test('equality: different id means not equal', () {
      final badge1 = BadgeModel(
        id: 'badge-1',
        name: 'Test',
        description: 'Desc',
        iconName: 'star',
        earnedAt: DateTime(2024),
      );
      final badge2 = BadgeModel(
        id: 'badge-2',
        name: 'Test',
        description: 'Desc',
        iconName: 'star',
        earnedAt: DateTime(2024),
      );

      expect(badge1, isNot(equals(badge2)));
    });

    test('hashCode is based on id', () {
      final badge = BadgeModel(
        id: 'badge-abc',
        name: 'Test',
        description: 'Desc',
        iconName: 'star',
        earnedAt: DateTime(2024),
      );

      expect(badge.hashCode, 'badge-abc'.hashCode);
    });
  });
}
