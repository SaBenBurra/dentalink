import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/shared/widgets/feed_video.dart';
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

  test('listede çerçeve en fazla kare, post sayfasında 4:5', () {
    expect(postMediaAspectRatio(1080, 1080), 1.0);
    expect(postMediaAspectRatio(1080, 1350), 1.0); // dikey → kareye kırpılır
    expect(postMediaAspectRatio(1080, 1350, minRatio: 0.8), 0.8);
    expect(postMediaAspectRatio(1080, 1920, minRatio: 0.8), 0.8); // 9:16 → 4:5
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
    'video kendiliğinden oynar; dokununca galeride büyür ve baştan başlar; kaydırınca diğer medya',
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
      expect(find.byType(FeedVideo), findsOneWidget);
      expect(video.plays, 1, reason: 'listede kendiliğinden oynar');
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

      // Videoya dokun: listedeki durur, galeri video sayfasında açılır ve baştan başlar.
      await tester.tap(slider);
      await settle(tester);
      expect(video.pauses, greaterThan(0), reason: 'listedeki video durdu');
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
      expect(video.plays, 2, reason: 'galerideki video kendiliğinden başladı');
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
      expect(
        inGallery,
        findsNWidgets(2),
        reason: 'ortada ve kontrol satırında',
      );
      expect(video.plays, 2, reason: 'yeniden başlamadı');
    },
  );

  testWidgets(
    'listede yalnızca ekrandaki video oynar; ses ikonu tüm videolar için geçerli',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(() => videoMuted.value = true);
      final video = FakeVideoPlatform();
      VideoPlayerPlatform.instance = video;
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              controller: scroll,
              children: [
                const PostMedia(
                  media: [
                    (
                      id: 'v',
                      url: 'https://x/t.jpg',
                      videoUrl: 'https://x/v.mp4',
                    ),
                  ],
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      await settle(tester);
      expect(video.plays, 1, reason: 'ekranda: oynar');
      expect(video.volume, 0, reason: 'sessiz başlar');

      // Ses ikonu galeriyi açmaz, sesi açar.
      await tester.tap(find.byType(VideoSoundButton));
      await settle(tester);
      expect(find.byType(FullscreenImageViewer), findsNothing);
      expect(videoMuted.value, isFalse);
      expect(video.volume, 1);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Ekrandan çıkınca durur, geri gelince devam eder.
      final pauses = video.pauses;
      scroll.jumpTo(600);
      await settle(tester);
      expect(video.pauses, pauses + 1);
      scroll.jumpTo(0);
      await settle(tester);
      expect(video.plays, 2);
    },
  );

  // Sayaç ve noktalar görselin üstünde; dokunuş karta düşmemeli.
  final overlays = <String, Finder Function()>{
    'sayaç': () => find.text('1/3'),
    'noktalar': () => find
        .descendant(
          of: find.byType(PostMedia),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  };
  for (final MapEntry(key: name, value: target) in overlays.entries) {
    testWidgets('$name dokunuşu galeriyi açar, kartı değil', (tester) async {
      var cardTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Kare çerçeve ekrana sığsın (test ekranı 800x600): noktalar altta.
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                // Feed kartı gibi: kartın tamamı post sayfasını açar.
                child: InkWell(
                  onTap: () => cardTaps++,
                  child: PostMedia(
                    media: [
                      for (final u in urls) (id: u, url: u, videoUrl: null),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Hedef dokunmayı geçirir; dokunuş alttaki görsele iner.
      await tester.tap(target(), warnIfMissed: false);
      await settle(tester);

      expect(find.byType(FullscreenImageViewer), findsOneWidget);
      expect(cardTaps, 0);
    });
  }
}
