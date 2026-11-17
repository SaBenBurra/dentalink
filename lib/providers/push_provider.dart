// shortcut: FCM token API (firebase_messaging 17'de deprecated, hâlâ çalışıyor); HTTP v1'in FID ile gönderimi netleşince register()/onRegistered'a geç.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/generated/app_localizations.dart';
import '../core/push/message_notifications.dart';
import '../core/router/app_router.dart';
import '../core/router/notification_route.dart';
import '../data/models/enums.dart';
import '../data/providers/repository_providers.dart';
import '../data/repositories/push_repository.dart';
import '../features/settings/providers/verification_provider.dart';
import 'auth_provider.dart';

/// main.dart'ta Firebase başlatılabildiyse true ile override edilir. Firebase
/// yapılandırma dosyaları yokken (docs/SUPABASE.md §8) push kapalıdır.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Oturum açık kullanıcının cihazını push'a kaydeder ve bildirim dokunuşlarını
/// açar. Kullanıcı değişince/çıkınca yeniden kurulur. MainApp izler.
final pushProvider = Provider<PushController?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return null;
  final uid = ref.watch(currentUserProvider.select((u) => u?.id));
  if (uid == null) return null;
  // 066: doğrulanmamışken duyuru tercihi yazılmaz (sunucu kilitli); onaylanınca
  // yeniden kurulur ve tercih yazılır.
  final verified = ref.watch(
    currentUserProvider.select((u) => u?.isVerified ?? false),
  );
  final controller = PushController(
    ref.read(pushRepositoryProvider),
    FirebaseMessaging.instance,
    ref.read(routerProvider),
    () => ref.read(announcementsEnabledProvider),
    verified: verified,
    onVerificationDecision: () => ref.invalidate(verificationProvider),
  )..start();
  ref.onDispose(controller.cancel);
  return controller;
});

/// 061'de duyurular bu FCM topic'ine gidiyordu; 067'den beri cihaz token'larına
/// gider. Eski abonelik açılışta kaldırılır.
const announcementsTopic = 'announcements';

/// Panel duyurularını alma tercihi (cihaz ayarı, varsayılan açık). Sunucuda
/// bu cihazın token'ına yazılır (067); çıkışta token zaten silinir.
/// `main` [SharedPreferences] ile override eder (testlerde yalnızca bellekte).
final announcementsEnabledProvider =
    NotifierProvider<AnnouncementsNotifier, bool>(AnnouncementsNotifier.new);

class AnnouncementsNotifier extends Notifier<bool> {
  AnnouncementsNotifier([this._prefs]);

  final SharedPreferences? _prefs;
  static const _key = 'announcements_enabled';

  @override
  bool build() => _prefs?.getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    _prefs?.setBool(_key, value);
    ref.read(pushProvider)?.syncAnnouncements(value);
  }
}

/// Push verisinden (Edge Function `push`) açılacak rota.
String? pushRoute(Map<String, dynamic> data) {
  final String? type = data['type'];
  // Duyuru: gönderiye bağlıysa gönderi, değilse yalnızca uygulama açılır.
  if (type == 'announcement') {
    final String? postId = data['post_id'];
    return postId == null || postId.isEmpty ? null : '/post/$postId';
  }
  // Belge doğrulama kararı (065).
  if (type == 'verification') return '/settings/verification';
  final notificationType = NotificationType.values
      .where((e) => e.dbValue == type)
      .firstOrNull;
  if (notificationType == null) return null;
  return notificationRoute(
    type: notificationType,
    actorId: data['actor_id'] ?? '',
    actorName: data['actor_name'] ?? '',
    actorAvatar: data['actor_avatar'],
    postId: data['post_id'],
    commentId: data['comment_id'],
  );
}

class PushController {
  PushController(
    this._repo,
    this._messaging,
    this._router,
    this._announcementsEnabled, {
    required this.verified,
    required this.onVerificationDecision,
  });

  final PushRepository _repo;
  final FirebaseMessaging _messaging;
  final GoRouter _router;
  final bool Function() _announcementsEnabled;

  /// Doğrulanmamış hesapta sunucu tercih RPC'sini reddeder (066).
  final bool verified;

  /// Doğrulama kararı uygulama açıkken geldi: ekran durumu yeniden okusun.
  final VoidCallback onVerificationDecision;
  final _subs = <StreamSubscription<Object?>>[];
  bool _cancelled = false;

  // Push hata verirse uygulama çalışmaya devam eder; yalnızca loglanır.
  Future<void> start() async {
    _subs
      ..add(_messaging.onTokenRefresh.listen(_register))
      ..add(FirebaseMessaging.onMessage.listen(_onForeground))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data)));
    try {
      final launch = await initMessageNotifications(_open);
      if (launch != null) _open(launch);
      // İzin penceresi OTP başarı animasyonunu ve kayıt adımlarını kesmesin.
      final ready = Completer<void>();
      _whenReady(ready.complete);
      await ready.future;
      if (_cancelled) return;
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        final token = await _messaging.getToken();
        if (token != null) await _register(token);
      }
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial.data);
    } catch (e) {
      debugPrint('push start: $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      await _repo.register(token, Platform.isIOS ? 'ios' : 'android');
    } catch (e) {
      debugPrint('push register: $e');
    }
    await syncAnnouncements(_announcementsEnabled());
  }

  Future<void> syncAnnouncements(bool enabled) async {
    if (_cancelled) return;
    try {
      // 061 sürümünün abone ettiği topic'e artık gönderilmiyor; temizlik.
      await _messaging.unsubscribeFromTopic(announcementsTopic);
      if (!verified) return;
      final token = await _messaging.getToken();
      if (token != null) await _repo.setAnnouncements(token, enabled);
    } catch (e) {
      debugPrint('push announcements: $e');
    }
  }

  // Uygulama açıkken: DM bildirimi, o sohbet ekranında değilsek gösterilir.
  void _onForeground(RemoteMessage message) {
    if (message.data['type'] == 'announcement') {
      _showAnnouncement(message);
      return;
    }
    if (message.data['type'] == 'verification') {
      onVerificationDecision();
      return;
    }
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (path == '/chat/${message.data['actor_id']}') return;
    showMessageNotification(
      message.data,
    ).catchError((Object e) => debugPrint('push foreground: $e'));
  }

  // Sistem uygulama açıkken duyuruyu göstermez; uygulama içinde gösterilir.
  void _showAnnouncement(RemoteMessage message) {
    final notification = message.notification;
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (notification == null || context == null) return;
    final route = pushRoute(message.data);
    final l10n = AppLocalizations.of(context)!;
    // SnackBar zemini iki temada da koyu; aksiyon rengi onun üstünde okunur.
    final accent = Theme.of(context).snackBarTheme.actionTextColor;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.campaign_outlined, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.announcementLabel}\n',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: accent),
                    ),
                    TextSpan(
                      text: notification.title ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: '\n${notification.body ?? ''}'),
                  ],
                ),
              ),
            ),
          ],
        ),
        action: route == null
            ? null
            : SnackBarAction(
                label: l10n.announcementOpen,
                onPressed: () => pushDetailOn(_router, route),
              ),
      ),
    );
  }

  void _open(Map<String, dynamic> data) {
    final route = pushRoute(data);
    if (route != null) _whenReady(() => pushDetailOn(_router, route));
  }

  // Soğuk açılışta ve girişte router önce /splash, /login → /feed yönlendirmesini
  // yapar; [action] uygulama içi bir sayfaya varınca çalışır.
  void _whenReady(VoidCallback action) {
    bool ready() => !const {
      '/',
      '/splash',
      '/login',
      '/register',
      '/auth-error',
    }.contains(_router.routerDelegate.currentConfiguration.uri.path);
    if (ready()) {
      action();
      return;
    }
    late final VoidCallback listener;
    listener = () {
      if (!ready()) return;
      _router.routerDelegate.removeListener(listener);
      action();
    };
    _router.routerDelegate.addListener(listener);
  }

  void cancel() {
    _cancelled = true;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  /// Çıkışta (oturum hâlâ açıkken) çağrılır: token sunucudan silinir ve cihazda
  /// geçersiz kılınır; RPC düşse bile eski kullanıcıya push gelmez (FCM
  /// UNREGISTERED döner, Edge Function satırı siler).
  Future<void> unregister() async {
    cancel();
    try {
      await cancelAllMessageNotifications();
    } catch (e) {
      debugPrint('push cancel notifications: $e');
    }
    try {
      final token = await _messaging.getToken();
      if (token != null) await _repo.unregister(token);
    } catch (e) {
      debugPrint('push unregister: $e');
    }
    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('push deleteToken: $e');
    }
  }
}
