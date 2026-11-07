import 'package:dentigo/core/utils/video_prepare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('video en fazla 60 sn; ölçüm kayması için yarım saniye pay', () {
    expect(isAcceptableVideoDuration(const Duration(seconds: 59)), isTrue);
    expect(
      isAcceptableVideoDuration(const Duration(milliseconds: 60400)),
      isTrue,
    );
    expect(isAcceptableVideoDuration(const Duration(seconds: 61)), isFalse);
  });
}
