import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/tag_model.dart';

void main() {
  group('TagModel -', () {
    test('constructor sets correct defaults', () {
      final tag = TagModel(
        id: 'tag-1',
        name: 'endodonti',
        slug: 'endodonti',
      );

      expect(tag.id, 'tag-1');
      expect(tag.name, 'endodonti');
      expect(tag.slug, 'endodonti');
      expect(tag.usageCount, 0);
    });

    test('constructor with usageCount', () {
      final tag = TagModel(
        id: 'tag-2',
        name: 'Ortodonti',
        slug: 'ortodonti',
        usageCount: 42,
      );

      expect(tag.usageCount, 42);
    });

    test('equality: same id means equal', () {
      final a = TagModel(id: 't-1', name: 'A', slug: 'a');
      final b = TagModel(id: 't-1', name: 'B', slug: 'b', usageCount: 99);
      expect(a, equals(b));
    });

    test('equality: different id means not equal', () {
      final a = TagModel(id: 't-1', name: 'A', slug: 'a');
      final b = TagModel(id: 't-2', name: 'A', slug: 'a');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final tag = TagModel(id: 'tag-xyz', name: 'Test', slug: 'test');
      expect(tag.hashCode, 'tag-xyz'.hashCode);
    });
  });
}
