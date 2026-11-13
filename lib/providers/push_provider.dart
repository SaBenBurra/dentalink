// shortcut: FCM token API (firebase_messaging 17'de deprecated, hâlâ çalışıyor); HTTP v1'in FID ile gönderimi netleşince register()/onRegistered'a geç.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/push/message_notifications.dart';
import '../core/router/app_router.dart';
import '../core/router/notification_route.dart';
import '../data/models/enums.dart';
import '../data/providers/repository_providers.dart';
import '../data/repositories/push_repository.dart';
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
  final controller = PushController(
    ref.read(pushRepositoryProvider),
    FirebaseMessaging.instance,
    ref.read(routerProvider),
    () => ref.read(announcementsEnabledProvider),
  )..start();
  ref.onDispose(controller.cancel);
  return controller;
});

/// Panel duyuruları (061) bu FCM topic'ine gider.
const announcementsTopic = 'announcements';

/// Panel duyurularını alma tercihi (cihaz ayarı, varsayılan açık). Kapatınca
/// topic aboneliği kalkar; çıkışta `deleteToken` aboneliği zaten siler.
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
    this._announcementsEnabled,
  );

  final PushRepository _repo;
  final FirebaseMessaging _messaging;
  final GoRouter _router;
  final bool Function() _announcementsEnabled;
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
      if (enabled) {
        await _messaging.subscribeToTopic(announcementsTopic);
      } else {
        await _messaging.unsubscribeFromTopic(announcementsTopic);
      }
    } catch (e) {
      debugPrint('push announcements: $e');
    }
  }

  // Uygulama açıkken: DM bildirimi, o sohbet ekranında değilsek gösterilir.
  void _onForeground(RemoteMessage message) {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (path == '/chat/${message.data['actor_id']}') return;
    showMessageNotification(
      message.data,
    ).catchError((Object e) => debugPrint('push foreground: $e'));
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
