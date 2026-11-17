import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sunucunun kapattığı oturumun sebebi (`user_banned` ya da `session_revoked`).
/// Giriş ekranı bir kez gösterir ve temizler.
final forcedSignOutReason = ValueNotifier<String?>(null);

/// Sunucu oturumu üye saymadı (doğrulama kaldırıldı; `X-Not-Verified`, 068).
/// Her yanıtta artar; [AuthNotifier] dinler ve profili doğrulanmamış yapar.
final notVerifiedSignal = ValueNotifier<int>(0);

/// Ban oturumları siler (057); PostgREST her istekten önce oturumu kontrol eder
/// ve silinmişse `X-Session-Revoked` başlığıyla reddeder (058). Hangi
/// repository'den gelirse gelsin ilk böyle yanıtta [onRevoked] çağrılır.
class SessionGuardClient extends http.BaseClient {
  SessionGuardClient(
    this._inner, {
    required this.onRevoked,
    required this.onNotVerified,
  });

  final http.Client _inner;
  final void Function(String reason) onRevoked;
  final void Function() onNotVerified;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    // Başlık adı büyük/küçük harf duyarsız; her client küçültmüyor.
    for (final h in response.headers.entries) {
      final key = h.key.toLowerCase();
      if (key == 'x-session-revoked') onRevoked(h.value);
      if (key == 'x-not-verified') onNotVerified();
    }
    return response;
  }

  @override
  void close() => _inner.close();
}
