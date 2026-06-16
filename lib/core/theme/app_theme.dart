import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

/// DentLink tema sistemi.
///
/// [lightTheme] ve [darkTheme] erişim noktaları.
/// İleride özel tema varyasyonları eklenebilir.
abstract final class AppTheme {
  /// Aydınlık tema.
  static ThemeData get light => buildLightTheme();

  /// Karanlık tema.
  static ThemeData get dark => buildDarkTheme();
}
