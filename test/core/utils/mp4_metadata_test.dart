import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dentigo/core/utils/mp4_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _box(String type, List<int> body) {
  final b = BytesBuilder()
    ..add((ByteData(4)..setUint32(0, body.length + 8)).buffer.asUint8List())
    ..add(latin1.encode(type))
    ..add(body);
  return b.toBytes();
}

const _gps = '+41.0082+028.9784/';

void main() {
  test(
    'konum ve metadata kutuları sıfırlanır; boyut ve video verisi aynı kalır',
    () async {
      final mdat = _box('mdat', List.filled(64, 7));
      final bytes = [
        ..._box('ftyp', latin1.encode('isom0000')),
        ..._box('moov', [
          ..._box('mvhd', List.filled(20, 1)),
          // Android MediaMuxer: udta/©xyz
          ..._box('udta', _box('©xyz', latin1.encode(_gps))),
          // iOS: meta/keys + ilst (ISO6709)
          ..._box(
            'meta',
            latin1.encode('com.apple.quicktime.location.ISO6709$_gps'),
          ),
          ..._box('trak', [
            ..._box('tkhd', List.filled(20, 2)),
            ..._box('udta', latin1.encode('name')),
          ]),
        ]),
        ...mdat,
      ];
      final dir = Directory.systemTemp.createTempSync('mp4meta');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/v.mp4')..writeAsBytesSync(bytes);

      expect(await stripMp4Metadata(file), 3);

      final out = file.readAsBytesSync();
      final text = latin1.decode(out);
      expect(out.length, bytes.length);
      expect(text, isNot(contains('41.0082')));
      expect(text, isNot(contains('ISO6709')));
      expect(text, isNot(contains('udta')));
      expect(text, contains('mvhd'));
      expect(text, contains('tkhd'));
      // Video verisi (mdat) yerinde ve değişmemiş.
      expect(out.sublist(out.length - mdat.length), mdat);
    },
  );

  test('moov yoksa hata: temizlenmemiş dosya yüklenmez', () async {
    final dir = Directory.systemTemp.createTempSync('mp4meta');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/v.mp4')
      ..writeAsBytesSync(_box('ftyp', latin1.encode('isom0000')));
    await expectLater(stripMp4Metadata(file), throwsFormatException);
  });
}
