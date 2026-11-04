import 'package:dentigo/data/models/message_model.dart';
import 'package:dentigo/features/messaging/screens/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';

MessageModel _msg(String sender, DateTime at) => MessageModel(
  id: '$sender$at',
  senderId: sender,
  receiverId: 'x',
  content: 'hi',
  createdAt: at,
);

void main() {
  final t = DateTime(2026, 10, 27, 23, 58);

  test('aynı gönderici, 5 dk içinde → aynı grup', () {
    expect(
      isSameMessageGroup(
        _msg('a', t),
        _msg('a', t.add(const Duration(minutes: 1))),
      ),
      isTrue,
    );
  });

  test('farklı gönderici, uzun ara, gün değişimi veya null → ayrı grup', () {
    expect(isSameMessageGroup(_msg('a', t), _msg('b', t)), isFalse);
    expect(
      isSameMessageGroup(
        _msg('a', t),
        _msg('a', t.add(const Duration(minutes: 5))),
      ),
      isFalse,
    );
    expect(
      isSameMessageGroup(
        _msg('a', t),
        _msg('a', t.add(const Duration(minutes: 3))),
      ),
      isFalse,
    );
    expect(isSameMessageGroup(null, _msg('a', t)), isFalse);
    expect(isSameMessageGroup(_msg('a', t), null), isFalse);
  });
}
