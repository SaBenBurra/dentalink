import 'dart:io';

import 'package:video_compress/video_compress.dart';

/// Gönderi videosu en fazla 60 sn (046).
const maxVideoDuration = Duration(seconds: 60);

/// `post-videos` bucket sınırı (046, 50 MB).
const maxVideoBytes = 50 * 1024 * 1024;

/// Sıkıştırılmış video hâlâ bucket sınırını aşıyor.
class VideoTooLargeException implements Exception {
  const VideoTooLargeException();
}

/// Kayan nokta süresi için yarım saniye pay: 60.3 sn'lik kayıt reddedilmez.
bool isAcceptableVideoDuration(Duration d) =>
    d <= maxVideoDuration + const Duration(milliseconds: 500);

/// Videonun süresi; okunamazsa null.
Future<Duration?> videoDuration(String path) async {
  final ms = (await VideoCompress.getMediaInfo(path)).duration;
  return ms == null ? null : Duration(milliseconds: ms.round());
}

/// Videoyu 720p mp4'e sıkıştırır ve kapak resmi (JPEG) çıkarır.
Future<({File image, File? video})> prepareVideo(File video) async {
  final info = await VideoCompress.compressVideo(
    video.path,
    quality: VideoQuality.Res1280x720Quality,
    includeAudio: true,
  );
  final file = info?.file;
  if (file == null) throw StateError('video compression failed');
  if (await file.length() > maxVideoBytes) throw const VideoTooLargeException();
  final thumbnail = await VideoCompress.getFileThumbnail(
    file.path,
    quality: 75,
  );
  return (image: thumbnail, video: file);
}
