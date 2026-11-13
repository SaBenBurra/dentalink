import 'package:dentigo/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? go(String location, {required bool required}) =>
      resolveVersionRedirect(location: location, required: required);

  test('zorunlu güncellemede her rota kilit ekranına gider', () {
    for (final location in [
      '/splash',
      '/login',
      '/register',
      '/feed',
      '/feed/post/1',
      '/legal/privacy',
      '/chat/u1',
    ]) {
      expect(
        go(location, required: true),
        '/update-required',
        reason: location,
      );
    }
    expect(go('/update-required', required: true), isNull);
  });

  test('kilit kalkınca açılış akışına döner, diğer rotalara dokunmaz', () {
    expect(go('/update-required', required: false), '/splash');
    expect(go('/feed', required: false), isNull);
    expect(go('/login', required: false), isNull);
  });
}
