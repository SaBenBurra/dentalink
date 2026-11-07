import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Metadata kutuları: konum (`©xyz`, `com.apple.quicktime.location.ISO6709`),
/// cihaz ve tarih etiketleri bunların içinde durur.
const _metadataBoxes = {'udta', 'meta'};

/// mp4'teki film ve iz düzeyi metadata kutularını `free` kutusuna çevirip içini
/// sıfırlar (KVKK: sıkıştırma kaynak videonun konumunu kopyalar). Kutu boyutları
/// değişmez, `mdat` ofsetleri geçerli kalır; dosyanın yalnızca `moov` kutusu okunur
/// ve yerinde yazılır. Temizlenen kutu sayısını döndürür; `moov` yoksa
/// [FormatException] (yüklenmez, konum sızmaz).
Future<int> stripMp4Metadata(File file) async {
  final raf = await file.open(mode: FileMode.append);
  try {
    final length = await raf.length();
    var offset = 0;
    while (offset + 8 <= length) {
      await raf.setPosition(offset);
      final box = _readHeader(await raf.read(16), 0, length - offset);
      if (box.type == 'moov') {
        await raf.setPosition(offset);
        final moov = await raf.read(box.size);
        final cleared = _clearChildren(moov, box.header, box.size);
        await raf.setPosition(offset);
        await raf.writeFrom(moov);
        return cleared;
      }
      offset += box.size;
    }
    throw const FormatException('moov box not found');
  } finally {
    await raf.close();
  }
}

/// [start, end) aralığındaki kutularda metadata'yı temizler; `trak` içine iner.
int _clearChildren(Uint8List buf, int start, int end) {
  var cleared = 0;
  var o = start;
  while (o + 8 <= end) {
    final box = _readHeader(buf, o, end - o);
    if (_metadataBoxes.contains(box.type)) {
      buf.setRange(o + 4, o + 8, ascii.encode('free'));
      buf.fillRange(o + box.header, o + box.size, 0);
      cleared++;
    } else if (box.type == 'trak') {
      cleared += _clearChildren(buf, o + box.header, o + box.size);
    }
    o += box.size;
  }
  return cleared;
}

({String type, int size, int header}) _readHeader(
  Uint8List buf,
  int o,
  int available,
) {
  final d = ByteData.sublistView(buf);
  var size = d.getUint32(o);
  var header = 8;
  if (size == 1) {
    size = d.getUint64(o + 8);
    header = 16;
  } else if (size == 0) {
    size = available; // dosya sonuna kadar
  }
  if (size < header || size > available) {
    throw const FormatException('invalid mp4 box size');
  }
  return (
    type: latin1.decode(buf.sublist(o + 4, o + 8)),
    size: size,
    header: header,
  );
}
