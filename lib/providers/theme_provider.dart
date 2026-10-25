import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının tema tercihini yöneten provider.
///
/// [ThemeMode.system] varsayılan değerdir — cihaz ayarına göre
/// otomatik olarak karanlık/aydınlık tema seçilir.
///
/// Kullanılabilir modlar:
/// - [ThemeMode.system]  → Cihaz ayarını takip eder
/// - [ThemeMode.light]   → Her zaman aydınlık
/// - [ThemeMode.dark]    → Her zaman karanlık
///
/// Tercih kalıcıdır: `main` önceden yüklenmiş [SharedPreferences] ile override
/// eder, böylece açılışta yanlış tema yanıp sönmez (UX-11). Override yoksa
/// (testler) tercih yalnızca bellekte tutulur.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeNotifier([this._prefs]);

  final SharedPreferences? _prefs;
  static const _key = 'theme_mode';

  @override
  ThemeMode build() =>
      ThemeMode.values.asNameMap()[_prefs?.getString(_key)] ?? ThemeMode.system;

  /// Tema modunu değiştirir ve kaydeder.
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs?.setString(_key, mode.name);
  }

  /// Karanlık ve aydınlık arasında geçiş yapar.
  /// Eğer sistem modundaysa, mevcut parlaklığa göre karşıt moda geçer.
  void toggle(Brightness currentBrightness) {
    if (state == ThemeMode.system) {
      setThemeMode(currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark);
    } else {
      setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
    }
  }
}
