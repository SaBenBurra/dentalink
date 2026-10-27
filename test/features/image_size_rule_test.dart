import 'package:dentlink/features/post/widgets/image_picker_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('absürt boyutlu görseller reddedilir', () {
    expect(isAcceptableImageSize(5, 100), isFalse);
    expect(isAcceptableImageSize(300, 300), isFalse); // kısa kenar < 320
    expect(isAcceptableImageSize(400, 2048), isFalse); // 1:4'ten dar
    expect(isAcceptableImageSize(2048, 400), isFalse);
  });

  test('normal fotoğraf ve panoramik röntgen kabul edilir', () {
    expect(isAcceptableImageSize(1536, 2048), isTrue);
    expect(isAcceptableImageSize(1152, 2048), isTrue); // 9:16
    expect(isAcceptableImageSize(2048, 820), isTrue); // ~2.5:1 OPG
    expect(isAcceptableImageSize(320, 1280), isTrue); // tam sınır
  });
}
