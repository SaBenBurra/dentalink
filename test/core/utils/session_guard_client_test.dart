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
}
