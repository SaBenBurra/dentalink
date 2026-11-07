import 'package:dentigo/shared/widgets/fullscreen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => openFullscreenImages(context, const [
              (id: '1', url: 'https://x/1.jpg', videoUrl: null),
              (id: '2', url: 'https://x/2.jpg', videoUrl: null),
            ]),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await settle(tester);
    expect(find.byType(FullscreenImageViewer), findsOneWidget);
  }

  testWidgets('aşağı ya da yukarı sürükleyince galeri kapanır', (tester) async {
    for (final dy in [300.0, -300.0]) {
      await open(tester);
      await tester.drag(find.byType(PageView), Offset(0, dy));
      await settle(tester);
      expect(find.byType(FullscreenImageViewer), findsNothing, reason: '$dy');
    }
  });

  testWidgets('kısa sürükleme kapatmaz, görsel yerine döner', (tester) async {
    await open(tester);
    final before = tester.getTopLeft(find.byType(PageView));
    // Yavaş, kısa sürükleme: mesafe ve hız eşiğin altında.
    final g = await tester.startGesture(before + const Offset(50, 300));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await settle(tester);
    expect(find.byType(FullscreenImageViewer), findsOneWidget);
    expect(tester.getTopLeft(find.byType(PageView)), before);
  });

  testWidgets('yatay kaydırma hâlâ sayfa değiştirir', (tester) async {
    await open(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(find.text('2 / 2'), findsOneWidget);
  });
}

// pumpAndSettle kullanılamaz: görsel testte yüklenmez, yükleme göstergesi hiç durmaz.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
