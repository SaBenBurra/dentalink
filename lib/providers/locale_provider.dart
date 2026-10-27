import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/generated/app_localizations.dart';

/// Desteklenen dillerin listesi.
const List<Locale> appSupportedLocales = [
  Locale('tr'), // Türkçe
  Locale('en'), // İngilizce
];

/// Cihazın sistem dilini okuyarak uygulamanın başlangıç dilini belirler.
///
/// Yalnızca **birincil** sistem diline bakılır (listede ilk sıradaki).
/// Cihazın birincil dili Türkçe ise → [Locale('tr')]
/// Diğer tüm diller için → [Locale('en')]
///
/// Not: [PlatformDispatcher.instance.locales] tüm tercih edilen dilleri
/// sırasıyla döner. İkincil dillere bakılmaz; aksi takdirde kullanıcı
/// İngilizce'yi birincil dil yapsa bile listede Türkçe varsa yanlış
/// sonuç dönerdi.
Locale _resolveDeviceLocale() {
  final systemLocales = WidgetsBinding.instance.platformDispatcher.locales;
  if (systemLocales.isEmpty) return const Locale('en');
  final primary = systemLocales.first;
  if (primary.languageCode == 'tr') return const Locale('tr');
  return const Locale('en');
}

/// Kullanıcının dil tercihini yöneten provider.
///
/// Ayarlardan seçilen dil kalıcıdır: `main` önceden yüklenmiş [SharedPreferences]
/// ile override eder (override yoksa, testlerde, yalnızca bellekte tutulur).
/// Seçim yapılmadıysa her açılışta cihazın sistem dili okunur:
/// - Cihaz dili **Türkçe** ise uygulama Türkçe başlar.
/// - Diğer tüm dillerde uygulama **İngilizce** başlar.
///
/// Kullanım:
/// ```dart
/// final locale = ref.watch(localeModeProvider);
/// ref.read(localeModeProvider.notifier).setLocale(const Locale('en'));
/// ref.read(localeModeProvider.notifier).toggle();
/// ```
final localeModeProvider = NotifierProvider<LocaleModeNotifier, Locale>(
  LocaleModeNotifier.new,
);

class LocaleModeNotifier extends Notifier<Locale> {
  LocaleModeNotifier([this._prefs]);

  final SharedPreferences? _prefs;
  static const _key = 'locale';

  /// Kullanıcı ayarlardan dil seçtiyse o, seçmediyse cihaz dili.
  @override
  Locale build() {
    final saved = _prefs?.getString(_key);
    return appSupportedLocales
            .where((l) => l.languageCode == saved)
            .firstOrNull ??
        _resolveDeviceLocale();
  }

  /// Dili değiştirir. [locale] değeri [appSupportedLocales] içinde olmalıdır.
  void setLocale(Locale locale) {
    assert(
      appSupportedLocales.contains(locale),
      'Desteklenmeyen dil: $locale. '
      'Lütfen appSupportedLocales listesine ekleyin.',
    );
    state = locale;
    _prefs?.setString(_key, locale.languageCode);
  }

  /// Türkçe ve İngilizce arasında geçiş yapar.
  void toggle() {
    setLocale(
      state.languageCode == 'tr' ? const Locale('en') : const Locale('tr'),
    );
  }

  /// Mevcut dilin Türkçe olup olmadığını döner.
  bool get isTurkish => state.languageCode == 'tr';

  /// Mevcut dilin İngilizce olup olmadığını döner.
  bool get isEnglish => state.languageCode == 'en';
}

/// Context'i olmayan controller'lar için aktif dilin metinleri.
final l10nProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(localeModeProvider)),
);
