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

  testWidgets(
    'iki parmakla yana kayan pinch sayfa değiştirmez, yakınlaştırır',
    (tester) async {
      await open(tester);
      final c = tester.getCenter(find.byType(PageView));
      final a = await tester.startGesture(c - const Offset(40, 0));
      final b = await tester.startGesture(c + const Offset(40, 0), pointer: 2);
      await tester.pump();
      // Parmaklar açılırken ikisi de sola kayar: eskiden sayfa kayıyordu.
      for (var i = 0; i < 10; i++) {
        await a.moveBy(const Offset(-20, 0));
        await b.moveBy(const Offset(-5, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await settle(tester);
      expect(find.text('1 / 2'), findsOneWidget);
      final zoom = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
          .transformationController!;
      expect(zoom.value.getMaxScaleOnAxis(), greaterThan(1));

      // Çift dokunuş küçültür, ardından yatay kaydırma yine sayfa değiştirir.
      await tester.tapAt(c);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(c);
      await settle(tester);
      expect(zoom.value.getMaxScaleOnAxis(), 1);
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await settle(tester);
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );
}

// pumpAndSettle kullanılamaz: görsel testte yüklenmez, yükleme göstergesi hiç durmaz.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
