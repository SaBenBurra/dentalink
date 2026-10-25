import 'dart:io';
import 'dart:typed_data';

import 'package:dentlink/core/utils/image_compress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('compress_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('kodlanan dosya .webp olur; null ve hata orijinali döndürür, sıra korunur', () async {
    final files = [for (final n in ['a.jpg', 'b.png', 'c.jpg']) File('${dir.path}/$n')];

    final out = await compressToWebp(files, encode: (path) async {
      if (path.endsWith('b.png')) return null;
      if (path.endsWith('c.jpg')) throw Exception('decode');
      return Uint8List.fromList([1, 2, 3]);
    });

    expect(out.map((f) => f.path), ['${files[0].path}.webp', files[1].path, files[2].path]);
    expect(out[0].readAsBytesSync(), [1, 2, 3]);
  });
}
