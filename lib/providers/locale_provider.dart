import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final systemLocales = ui.PlatformDispatcher.instance.locales;
  if (systemLocales.isEmpty) return const Locale('en');
  final primary = systemLocales.first;
  if (primary.languageCode == 'tr') return const Locale('tr');
  return const Locale('en');
}

/// Kullanıcının dil tercihini yöneten provider.
///
/// Uygulama ilk açıldığında cihazın sistem dili okunur:
/// - Cihaz dili **Türkçe** ise uygulama Türkçe başlar.
/// - Diğer tüm dillerde uygulama **İngilizce** başlar.
///
/// Kullanım:
/// ```dart
/// final locale = ref.watch(localeModeProvider);
/// ref.read(localeModeProvider.notifier).setLocale(const Locale('en'));
/// ref.read(localeModeProvider.notifier).toggle();
/// ```
final localeModeProvider =
    NotifierProvider<LocaleModeNotifier, Locale>(LocaleModeNotifier.new);

class LocaleModeNotifier extends Notifier<Locale> {
  @override
  Locale build() => _resolveDeviceLocale();

  /// Dili değiştirir. [locale] değeri [appSupportedLocales] içinde olmalıdır.
  void setLocale(Locale locale) {
    assert(
      appSupportedLocales.contains(locale),
      'Desteklenmeyen dil: $locale. '
      'Lütfen appSupportedLocales listesine ekleyin.',
    );
    state = locale;
  }

  /// Türkçe ve İngilizce arasında geçiş yapar.
  void toggle() {
    state = state.languageCode == 'tr' ? const Locale('en') : const Locale('tr');
  }

  /// Mevcut dilin Türkçe olup olmadığını döner.
  bool get isTurkish => state.languageCode == 'tr';

  /// Mevcut dilin İngilizce olup olmadığını döner.
  bool get isEnglish => state.languageCode == 'en';
}
