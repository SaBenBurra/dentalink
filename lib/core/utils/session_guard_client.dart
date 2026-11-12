import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sunucunun kapattığı oturumun sebebi (`user_banned` ya da `session_revoked`).
/// Giriş ekranı bir kez gösterir ve temizler.
final forcedSignOutReason = ValueNotifier<String?>(null);

/// Ban oturumları siler (057); PostgREST her istekten önce oturumu kontrol eder
/// ve silinmişse `X-Session-Revoked` başlığıyla reddeder (058). Hangi
/// repository'den gelirse gelsin ilk böyle yanıtta [onRevoked] çağrılır.
class SessionGuardClient extends http.BaseClient {
  SessionGuardClient(this._inner, {required this.onRevoked});

  final http.Client _inner;
  final void Function(String reason) onRevoked;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    // Başlık adı büyük/küçük harf duyarsız; her client küçültmüyor.
    for (final h in response.headers.entries) {
      if (h.key.toLowerCase() == 'x-session-revoked') onRevoked(h.value);
    }
    return response;
  }

  @override
  void close() => _inner.close();
}
