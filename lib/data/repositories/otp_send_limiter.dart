import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'otp_cooldown_exception.dart';

/// İstemci tarafı OTP gönderim sınırlayıcısı.
///
/// - Aynı hedefe [cooldown] içinde tekrar SMS/e-posta gönderilmez.
/// - [cooldown] penceresinde en fazla [maxDistinctDestinations] farklı
///   hedefe gönderim yapılabilir (SMS bombing engeli).
/// - Geçmiş [SharedPreferences] ile kalıcıdır; uygulama kapanıp açılınca
///   cooldown sıfırlanmaz.
class OtpSendLimiter {
  OtpSendLimiter({
    this.cooldown = const Duration(seconds: 60),
    this.maxDistinctDestinations = 2,
    this.persist = true,
  });

  static const _prefsKey = 'otp_send_history_v1';

  final Duration cooldown;
  final int maxDistinctDestinations;

  /// false ise yalnızca bellek (mock/test).
  final bool persist;

  final List<({String destination, DateTime sentAt})> _recent = [];
  final Set<String> _sentThisSession = {};
  bool _loaded = false;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    if (!persist) {
      _loaded = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final destination = item['d'];
            final sentAtMs = item['t'];
            if (destination is! String || sentAtMs is! num) continue;
            final sentAt = DateTime.fromMillisecondsSinceEpoch(
              sentAtMs.toInt(),
            );
            _recent.add((destination: destination, sentAt: sentAt));
            _sentThisSession.add(destination);
          }
        }
      }
      _prune(DateTime.now());
      await _persist();
    } finally {
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = _recent
        .map(
          (e) => {
            'd': e.destination,
            't': e.sentAt.millisecondsSinceEpoch,
          },
        )
        .toList();
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }

  void _prune(DateTime now) {
    _recent.removeWhere((e) => now.difference(e.sentAt) >= cooldown);
  }

  int _remainingSeconds(DateTime sentAt, DateTime now) {
    final remaining = cooldown - now.difference(sentAt);
    return remaining.inSeconds.clamp(1, cooldown.inSeconds);
  }

  /// Gönderim serbestse null, aksi halde fırlatılacak exception.
  /// Çağrıdan önce [ensureLoaded] tamamlanmış olmalı.
  OtpCooldownException? check(String destination) {
    final now = DateTime.now();
    _prune(now);

    DateTime? lastSame;
    for (final e in _recent) {
      if (e.destination == destination &&
          (lastSame == null || e.sentAt.isAfter(lastSame))) {
        lastSame = e.sentAt;
      }
    }
    if (lastSame != null) {
      return OtpCooldownException(
        remainingSeconds: _remainingSeconds(lastSame, now),
        sameDestination: true,
      );
    }

    final uniqueCount = _recent.map((e) => e.destination).toSet().length;
    if (uniqueCount >= maxDistinctDestinations) {
      final oldest = _recent
          .map((e) => e.sentAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      return OtpCooldownException(
        remainingSeconds: _remainingSeconds(oldest, now),
        sameDestination: false,
      );
    }

    return null;
  }

  /// Bu cihaz oturumunda (kalıcı geçmiş dahil) [destination] için
  /// başarılı gönderim yapıldı mı?
  bool hasSentTo(String destination) =>
      _sentThisSession.contains(destination);

  Future<void> recordSuccess(String destination) async {
    final now = DateTime.now();
    _prune(now);
    _sentThisSession.add(destination);
    _recent.add((destination: destination, sentAt: now));
    await _persist();
  }

  /// Sunucu rate-limit'inde aynı hedefin penceresini yenile.
  Future<void> touchRateLimit(String destination) async {
    final now = DateTime.now();
    _prune(now);
    _recent.removeWhere((e) => e.destination == destination);
    _recent.add((destination: destination, sentAt: now));
    await _persist();
  }
}
