// shortcut: FCM token API (firebase_messaging 17'de deprecated, hâlâ çalışıyor); HTTP v1'in FID ile gönderimi netleşince register()/onRegistered'a geç.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  )..start();
  ref.onDispose(controller.cancel);
  return controller;
});

/// Push verisinden (Edge Function `push`) açılacak rota.
String? pushRoute(Map<String, dynamic> data) {
  final String? type = data['type'];
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
  PushController(this._repo, this._messaging, this._router);

  final PushRepository _repo;
  final FirebaseMessaging _messaging;
  final GoRouter _router;
  final _subs = <StreamSubscription<Object?>>[];

  // Push hata verirse uygulama çalışmaya devam eder; yalnızca loglanır.
  Future<void> start() async {
    _subs
      ..add(_messaging.onTokenRefresh.listen(_register))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        final token = await _messaging.getToken();
        if (token != null) await _register(token);
      }
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial);
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
  }

  void _open(RemoteMessage message) {
    final route = pushRoute(message.data);
    if (route == null) return;
    // Soğuk açılışta router önce /login → /feed yönlendirmesini yapar; ondan sonra aç.
    bool ready() => !const {'/', '/login', '/register', '/auth-error'}
        .contains(_router.routerDelegate.currentConfiguration.uri.path);
    if (ready()) {
      _router.push(route);
      return;
    }
    late final VoidCallback listener;
    listener = () {
      if (!ready()) return;
      _router.routerDelegate.removeListener(listener);
      _router.push(route);
    };
    _router.routerDelegate.addListener(listener);
  }

  void cancel() {
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
