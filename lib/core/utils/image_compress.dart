import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

typedef WebpEncoder = Future<Uint8List?> Function(String path);

/// Görselleri yüklemeden önce WebP'ye çevirir (EXIF/konum bilgisi atılır).
/// Kodlanamayan dosya olduğu gibi döner; bucket JPEG/PNG'yi de kabul eder.
Future<List<File>> compressToWebp(
  List<File> files, {
  WebpEncoder encode = _encodeWebp,
}) =>
    Future.wait(files.map((f) async {
      try {
        final bytes = await encode(f.path);
        if (bytes == null) return f;
        return await File('${f.path}.webp').writeAsBytes(bytes, flush: true);
      } catch (e) {
        debugPrint('compressToWebp: ${f.path} kodlanamadı: $e');
        return f;
      }
    }));

// Boyutlandırmayı picker yapar (uzun kenar 2048); min boyutlar burada küçültmeyi kapatır.
Future<Uint8List?> _encodeWebp(String path) => FlutterImageCompress.compressWithFile(
      path,
      minWidth: 2048,
      minHeight: 2048,
      quality: 80,
      format: CompressFormat.webp,
    );
