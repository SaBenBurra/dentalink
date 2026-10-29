import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cihazın bir ağa bağlı olup olmadığı. Testlerde override edilir.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

/// Bilinmiyorsa (ilk an, plugin hatası) çevrimiçi sayılır; banner boşuna çıkmaz.
/// Ağ var ama internet yoksa da true döner; o durumu istek hataları gösterir.
final isOnlineProvider = Provider<bool>((ref) {
  final results = ref.watch(connectivityProvider).valueOrNull;
  return results == null || results.any((r) => r != ConnectivityResult.none);
});

/// Uygulama gizlendikten (arka plan) sonra her yeniden görünüşünde artar; izin
/// diyaloğu gibi kısa inactive geçişleri saymaz. Arka planda realtime kanalı kopar ve
/// aradaki olaylar (yeni mesaj, bildirim) kaçar.
final appResumeProvider = NotifierProvider<AppResumeNotifier, int>(AppResumeNotifier.new);

class AppResumeNotifier extends Notifier<int> {
  @override
  int build() {
    final listener = AppLifecycleListener(onShow: () => state++);
    ref.onDispose(listener.dispose);
    return 0;
  }
}

/// Bağlantı geri gelince (false → true) ya da uygulama ön plana dönünce
/// [onReconnect]'i çağırır. Realtime kanalları kopukken kaçan olaylar ve hata
/// durumları için.
void listenReconnect(Ref ref, void Function() onReconnect) {
  ref.listen<bool>(isOnlineProvider, (was, now) {
    if (was == false && now) onReconnect();
  });
  ref.listen<int>(appResumeProvider, (_, _) => onReconnect());
}
