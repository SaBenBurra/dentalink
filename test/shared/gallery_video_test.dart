import 'package:cached_network_image/cached_network_image.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/shared/widgets/gallery_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_video_platform.dart';

void main() {
  testWidgets('kapak videonun alanını doldurur; oynatınca alan değişmez', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    VideoPlayerPlatform.instance = FakeVideoPlatform();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: GalleryVideo(
            url: 'https://x/v.mp4',
            thumbUrl: 'https://x/t.jpg',
          ),
        ),
      ),
    );
    final area = find
        .descendant(
          of: find.byType(GalleryVideo),
          matching: find.byType(GestureDetector),
        )
        .first; // ikincisi oynatınca gelen ilerleme çubuğu
    final before = tester.getRect(area);
    expect(before.width, 400, reason: 'oynatmadan önce de ekran genişliği');
    // Görsel testte yüklenmese de kutusu alanın tamamı olmalı.
    expect(tester.getRect(find.byType(CachedNetworkImage)), before);

    await tester.tap(area);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(
      tester.getRect(area),
      before,
      reason: 'ilerleme çubuğu yer kaydırmaz',
    );
    // 16:9 video alanın genişliğini doldurur, kapak da aynı genişlikteydi.
    expect(tester.getSize(find.byType(VideoPlayer)).width, before.width);
  });
}
