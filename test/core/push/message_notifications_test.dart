import 'package:dentigo/core/push/message_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePushMessages', () {
    test('sunucunun [{text, at}] listesini sırayla çözer', () {
      final messages = parsePushMessages(
        '[{"text":"selam","at":"2026-10-30T22:00:00+00:00"},'
        '{"text":"orada mısın?","at":"2026-10-30T22:01:00+00:00"}]',
      );
      expect(messages.map((m) => m.text), ['selam', 'orada mısın?']);
      expect(messages.first.at, DateTime.utc(2026, 10, 30, 22).toLocal());
      expect(messages.last.at.isUtc, isFalse);
    });

    test('alan yoksa boş liste', () {
      expect(parsePushMessages(null), isEmpty);
      expect(parsePushMessages(''), isEmpty);
    });
  });
}
