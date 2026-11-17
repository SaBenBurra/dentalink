import 'package:dentigo/core/utils/session_guard_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'X-Session-Revoked başlığı sebebi bildirir, yanıt aynen döner',
    () async {
      final reasons = <String>[];
      final client = SessionGuardClient(
        MockClient(
          (req) async => req.url.path == '/revoked'
              ? http.Response(
                  '{"code":"user_banned"}',
                  401,
                  headers: {'X-Session-Revoked': 'user_banned'},
                )
              : http.Response('[]', 200),
        ),
        onRevoked: reasons.add,
        onNotVerified: () => fail('not_verified beklenmiyordu'),
      );

      final ok = await client.get(Uri.parse('https://x.test/ok'));
      expect(ok.statusCode, 200);
      expect(reasons, isEmpty);

      final revoked = await client.get(Uri.parse('https://x.test/revoked'));
      expect(revoked.statusCode, 401);
      expect(revoked.body, contains('user_banned'));
      expect(reasons, ['user_banned']);
    },
  );

  test('X-Not-Verified başlığı bildirir (068)', () async {
    var notVerified = 0;
    final client = SessionGuardClient(
      MockClient(
        (req) async => http.Response(
          '{"code":"not_verified"}',
          403,
          headers: {'x-not-verified': '1'},
        ),
      ),
      onRevoked: (_) => fail('oturum kapanmamalı'),
      onNotVerified: () => notVerified++,
    );

    final res = await client.get(Uri.parse('https://x.test/posts'));
    expect(res.statusCode, 403);
    expect(notVerified, 1);
  });
}
