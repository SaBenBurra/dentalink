import 'package:dentigo/features/messaging/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, MessageBubble bubble) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: bubble)));

  const avatar = Icon(Icons.person);

  testWidgets('saat ve avatar yalnızca grubun son balonunda', (tester) async {
    await pump(
      tester,
      const MessageBubble(
        text: 'a',
        isMe: false,
        time: '12:00',
        isLastInGroup: false,
        avatar: avatar,
      ),
    );
    expect(find.text('12:00'), findsNothing);
    expect(find.byIcon(Icons.person), findsNothing);

    await pump(
      tester,
      const MessageBubble(
        text: 'a',
        isMe: false,
        time: '12:00',
        avatar: avatar,
      ),
    );
    expect(find.text('12:00'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('kendi mesajında avatar yok, balon sağda', (tester) async {
    await pump(
      tester,
      const MessageBubble(text: 'a', isMe: true, time: '12:00', avatar: avatar),
    );
    expect(find.byIcon(Icons.person), findsNothing);
    expect(
      tester.getCenter(find.text('a')).dx,
      greaterThan(tester.getCenter(find.byType(MessageBubble)).dx),
    );
  });
}
