import 'package:dentlink/shared/widgets/fullscreen_image_viewer.dart';
import 'package:dentlink/shared/widgets/post_media.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const urls = ['https://x/1.jpg', 'https://x/2.jpg', 'https://x/3.jpg'];

  // Feed'deki gibi: görsel, yatay kaydırılan sekme PageView'ının içinde.
  Widget app() => MaterialApp(
    home: Scaffold(
      body: PageView(
        key: const Key('tabs'),
        controller: PageController(),
        children: [
          ListView(
            children: [
              PostMedia(imageUrls: urls, isLiked: false, onLikeToggle: () {}),
            ],
          ),
          const Text('ikinci sekme'),
        ],
      ),
    ),
  );

  // pumpAndSettle kullanılamaz: görsel testte yüklenmez, yükleme göstergesi hiç durmaz.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  int page(WidgetTester tester, Finder pageView) =>
      tester.widget<PageView>(pageView).controller!.page!.round();

  testWidgets('görselde kaydırma slider\'ı çevirir, sekmeyi değil', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final slider = find.descendant(
      of: find.byType(PostMedia),
      matching: find.byType(PageView),
    );

    await tester.fling(slider, const Offset(-300, 0), 1000);
    await settle(tester);

    expect(page(tester, slider), 1);
    expect(page(tester, find.byKey(const Key('tabs'))), 0);
  });

  testWidgets('çoklu görselde sayaç kaydırınca güncellenir', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('1/3'), findsOneWidget);

    await tester.fling(
      find.descendant(
        of: find.byType(PostMedia),
        matching: find.byType(PageView),
      ),
      const Offset(-300, 0),
      1000,
    );
    await settle(tester);
    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('tek görselde sayaç yok', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostMedia(
            imageUrls: const ['https://x/1.jpg'],
            isLiked: false,
            onLikeToggle: () {},
          ),
        ),
      ),
    );
    expect(find.text('1/1'), findsNothing);
  });

  testWidgets('görsele dokununca tam ekran, tıklanan görselden açılır', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final slider = find.descendant(
      of: find.byType(PostMedia),
      matching: find.byType(PageView),
    );
    await tester.fling(slider, const Offset(-300, 0), 1000);
    await settle(tester);

    await tester.tap(slider);
    // onDoubleTap olduğundan tek dokunuş çift dokunma süresi kadar bekler.
    await tester.pump(kDoubleTapTimeout);
    await settle(tester);

    expect(find.byType(FullscreenImageViewer), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await settle(tester);
    expect(find.byType(FullscreenImageViewer), findsNothing);
  });
}
