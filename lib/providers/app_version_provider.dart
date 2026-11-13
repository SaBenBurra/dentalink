import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/app_config.dart';
import '../data/providers/repository_providers.dart';
import 'connectivity_provider.dart';

/// Sürüm kontrolü (migration 062, ROADMAP Faz 5).
enum AppVersionStatus { upToDate, updateAvailable, updateRequired }

/// `x.y.z` → sayılar; build no ve başka biçimler kabul edilmez (null).
List<int>? parseVersion(String version) {
  final parts = version.trim().split('.');
  if (parts.length != 3) return null;
  final numbers = parts.map(int.tryParse).toList();
  if (numbers.any((n) => n == null || n < 0)) return null;
  return numbers.cast<int>();
}

/// Sayısal karşılaştırma (`1.10.0 > 1.9.0`); biri bozuksa null.
int? compareVersions(String a, String b) {
  final x = parseVersion(a), y = parseVersion(b);
  if (x == null || y == null) return null;
  for (var i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return 0;
}

/// Ayar yoksa ya da sürüm okunamıyorsa güncel sayılır: kimse yanlışlıkla kilitlenmez.
AppVersionStatus resolveVersionStatus(String current, AppConfig? config) {
  if (config == null) return AppVersionStatus.upToDate;
  final vsMin = compareVersions(current, config.minSupportedVersion);
  final vsLatest = compareVersions(current, config.latestVersion);
  if (vsMin == null || vsLatest == null) return AppVersionStatus.upToDate;
  if (vsMin < 0) return AppVersionStatus.updateRequired;
  if (vsLatest < 0) return AppVersionStatus.updateAvailable;
  return AppVersionStatus.upToDate;
}

/// Yüklü uygulamanın sürümü (`pubspec` version, build no hariç). Testlerde override edilir.
final currentAppVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

/// `app_config.platform` değeri.
final appPlatformProvider = Provider<String>(
  (ref) => Platform.isIOS ? 'ios' : 'android',
);

typedef VersionCheck = ({AppVersionStatus status, AppConfig? config});

/// Açılışta ve uygulama ön plana her dönüşte yeniden okunur.
final versionCheckProvider = FutureProvider<VersionCheck>((ref) async {
  ref.watch(appResumeProvider);
  try {
    final current = await ref.watch(currentAppVersionProvider.future);
    final config = await ref
        .read(appConfigRepositoryProvider)
        .fetch(ref.read(appPlatformProvider));
    return (status: resolveVersionStatus(current, config), config: config);
  } catch (e) {
    // Çevrimdışı ya da sunucu hatası: güncel sayılır (ROADMAP, "hata durumu açık kalır").
    debugPrint('Sürüm kontrolü okunamadı: $e');
    return (status: AppVersionStatus.upToDate, config: null);
  }
});

/// Yeniden okunurken önceki sonuç korunur; ekran kilit ile normal akış arasında gidip gelmez.
final appVersionStatusProvider = Provider<AppVersionStatus>(
  (ref) =>
      ref.watch(versionCheckProvider).valueOrNull?.status ??
      AppVersionStatus.upToDate,
);

/// "Yeni sürüm var" şeridinin kapatıldığı `latest_version`; yeni sürüm gelince
/// şerit yeniden görünür. `main` [SharedPreferences] ile override eder.
final dismissedUpdateProvider =
    NotifierProvider<DismissedUpdateNotifier, String?>(
      DismissedUpdateNotifier.new,
    );

class DismissedUpdateNotifier extends Notifier<String?> {
  DismissedUpdateNotifier([this._prefs]);

  final SharedPreferences? _prefs;
  static const _key = 'dismissed_update_version';

  @override
  String? build() => _prefs?.getString(_key);

  void dismiss(String latestVersion) {
    state = latestVersion;
    _prefs?.setString(_key, latestVersion);
  }
}
