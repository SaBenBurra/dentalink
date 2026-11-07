import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/shared/widgets/gallery_video.dart';
import 'package:dentigo/shared/widgets/fullscreen_image_viewer.dart';
import 'package:dentigo/shared/widgets/post_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_video_platform.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

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
              PostMedia(
                media: [for (final u in urls) (id: u, url: u, videoUrl: null)],
              ),
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

  test('çerçeve oranı 4:5 ile 1.91:1 arasında sınırlanır', () {
    expect(postMediaAspectRatio(1080, 1080), 1.0);
    expect(postMediaAspectRatio(1080, 1350), 0.8);
    expect(postMediaAspectRatio(1080, 1920), 0.8); // 9:16 → 4:5'e kırpılır
    expect(postMediaAspectRatio(1920, 1080), closeTo(1.78, 0.01));
    expect(postMediaAspectRatio(3000, 1000), 1.91);
    expect(postMediaAspectRatio(100, 0), 1.0);
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
            media: const [(id: '1', url: 'https://x/1.jpg', videoUrl: null)],
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
    await settle(tester);

    expect(find.byType(FullscreenImageViewer), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await settle(tester);
    expect(find.byType(FullscreenImageViewer), findsNothing);
  });

  testWidgets(
    'videoya dokununca galeri o sayfada açılır ve video hemen başlar; kaydırınca diğer medya',
    (tester) async {
      final video = FakeVideoPlatform();
      VideoPlayerPlatform.instance = video;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PostMedia(
              media: const [
                (id: '1', url: 'https://x/1.jpg', videoUrl: null),
                (id: 'v', url: 'https://x/t.jpg', videoUrl: 'https://x/v.mp4'),
                (id: '2', url: 'https://x/2.jpg', videoUrl: null),
              ],
            ),
          ),
        ),
      );
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

      final slider = find.descendant(
        of: find.byType(PostMedia),
        matching: find.byType(PageView),
      );
      await tester.fling(slider, const Offset(-300, 0), 1000);
      await settle(tester);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Videoya dokun: galeri video sayfasında açılır, video kendiliğinden başlar.
      await tester.tap(slider);
      await settle(tester);
      expect(find.byType(FullscreenImageViewer), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
      final inGallery = find.descendant(
        of: find.byType(FullscreenImageViewer),
        matching: find.byIcon(Icons.play_arrow_rounded),
      );
      expect(
        tester.widget<GalleryVideo>(find.byType(GalleryVideo)).autoplay,
        isTrue,
      );
      expect(video.plays, 1, reason: 'video kendiliğinden başladı');
      expect(inGallery, findsNothing, reason: 'oynarken simge yok');

      // Kaydırınca postun diğer medyası.
      final gallery = find.descendant(
        of: find.byType(FullscreenImageViewer),
        matching: find.byType(PageView),
      );
      await tester.fling(gallery, const Offset(-400, 0), 1000);
      await settle(tester);
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.fling(gallery, const Offset(400, 0), 1000);
      await settle(tester);
      await tester.fling(gallery, const Offset(400, 0), 1000);
      await settle(tester);
      expect(find.text('1 / 3'), findsOneWidget);

      // Kaydırarak geri gelinen video kendiliğinden başlamaz: kapak + oynat simgesi.
      await tester.fling(gallery, const Offset(-400, 0), 1000);
      await settle(tester);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(
        tester.widget<GalleryVideo>(find.byType(GalleryVideo)).autoplay,
        isFalse,
      );
      expect(inGallery, findsOneWidget);
      expect(video.plays, 1, reason: 'yeniden başlamadı');
    },
  );
}
