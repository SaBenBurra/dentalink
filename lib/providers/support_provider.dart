import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/models/support_model.dart';
import '../data/providers/repository_providers.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

/// Her mesajla gönderilen platform ve sürüm, ör. "android 1.0.0 (12)".
final supportClientInfoProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${defaultTargetPlatform.name} ${info.version} (${info.buildNumber})';
});

/// Kullanıcının destek sohbeti; hiç yazmadıysa null. Mesajlar'daki sabit satır
/// ve alt menü rozeti de bunu izler.
class SupportThreadNotifier extends AutoDisposeAsyncNotifier<SupportThread?> {
  @override
  Future<SupportThread?> build() async {
    final uid = ref.watch(authProvider.select((s) => s.valueOrNull?.id));
    if (uid == null) return null;
    listenReconnect(ref, ref.invalidateSelf);

    final repo = ref.watch(supportRepositoryProvider);
    final sub = repo
        .watchThread(uid)
        .listen(
          (t) => state = AsyncData(t),
          onError: (Object e) => debugPrint('SupportThreadNotifier: $e'),
        );
    ref.onDispose(sub.cancel);
    return repo.getThread();
  }

  Future<void> markRead() async {
    final thread = state.valueOrNull;
    if (thread == null || !thread.hasUnread) return;
    await ref.read(supportRepositoryProvider).markRead(thread.id);
    // user_read_at değişikliği realtime ile gelir.
  }
}

final supportThreadProvider =
    AsyncNotifierProvider.autoDispose<SupportThreadNotifier, SupportThread?>(
      SupportThreadNotifier.new,
    );

/// id ile tekilleştirir, eski → yeni sıralar.
List<SupportMessage> _merge(
  List<SupportMessage> a,
  Iterable<SupportMessage> b,
) => {
  for (final m in [...a, ...b]) m.id: m,
}.values.toList()..sort((x, y) => x.createdAt.compareTo(y.createdAt));

class SupportChatNotifier
    extends AutoDisposeAsyncNotifier<List<SupportMessage>> {
  @override
  Future<List<SupportMessage>> build() async {
    final threadId = ref.watch(
      supportThreadProvider.select((t) => t.valueOrNull?.id),
    );
    if (threadId == null) return const [];
    listenReconnect(ref, ref.invalidateSelf);

    final repo = ref.watch(supportRepositoryProvider);
    // İlk yükleme sürerken gelen mesajlar kaybolmasın.
    final early = <SupportMessage>[];
    var loaded = false;
    final sub = repo
        .watchMessages(threadId)
        .listen(
          (m) => loaded ? _add([m]) : early.add(m),
          onError: (Object e) => debugPrint('SupportChatNotifier: $e'),
        );
    ref.onDispose(sub.cancel);

    final messages = await repo.getMessages(threadId);
    loaded = true;
    return _merge(messages, early);
  }

  void _add(Iterable<SupportMessage> ms) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(_merge(current, ms));
  }

  /// [category] yalnızca ilk mesajda anlamlı; sonra DB eskisini korur.
  Future<void> send(String content, {SupportCategory? category}) async {
    final clientInfo = await ref.read(supportClientInfoProvider.future);
    final message = await ref
        .read(supportRepositoryProvider)
        .send(content, category: category, clientInfo: clientInfo);
    final current = await future;
    state = AsyncData(_merge(current, [message]));
    // İlk mesaj sohbeti oluşturdu: sohbet yeniden çekilince build bu
    // sohbetin kanalına abone olur ve mesajları baştan yükler.
    if (ref.read(supportThreadProvider).valueOrNull == null) {
      ref.invalidate(supportThreadProvider);
    }
  }
}

final supportChatProvider =
    AsyncNotifierProvider.autoDispose<
      SupportChatNotifier,
      List<SupportMessage>
    >(SupportChatNotifier.new);
