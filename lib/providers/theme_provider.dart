import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcının tema tercihini yöneten provider.
///
/// [ThemeMode.system] varsayılan değerdir — cihaz ayarına göre
/// otomatik olarak karanlık/aydınlık tema seçilir.
///
/// Kullanılabilir modlar:
/// - [ThemeMode.system]  → Cihaz ayarını takip eder
/// - [ThemeMode.light]   → Her zaman aydınlık
/// - [ThemeMode.dark]    → Her zaman karanlık
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Tema modunu değiştirir.
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  /// Karanlık ve aydınlık arasında geçiş yapar.
  /// Eğer sistem modundaysa, mevcut parlaklığa göre karşıt moda geçer.
  void toggle(Brightness currentBrightness) {
    if (state == ThemeMode.system) {
      state = currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    } else {
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
  }
}
