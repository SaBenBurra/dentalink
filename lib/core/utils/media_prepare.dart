import 'dart:io';

import 'image_compress.dart';
import 'video_prepare.dart';

/// Formda seçilen medya, kullanıcının belirlediği sırayla.
typedef PickedMedia = ({File file, bool isVideo});

/// Görselleri WebP'ye, videoyu 720p'ye çevirir; sıra korunur.
/// Sonuç `MediaUpload` biçimindedir (kapak/görsel + varsa video).
Future<List<({File image, File? video})>> prepareMedia(
  List<PickedMedia> picked,
) async {
  final images = await compressToWebp([
    for (final p in picked)
      if (!p.isVideo) p.file,
  ]);
  var next = 0;
  return [
    for (final p in picked)
      if (p.isVideo)
        await prepareVideo(p.file)
      else
        (image: images[next++], video: null),
  ];
}
