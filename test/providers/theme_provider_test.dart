import 'package:dentlink/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('tema tercihi kaydedilir ve açılışta okunur (UX-11)', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      themeModeProvider.overrideWith(() => ThemeModeNotifier(prefs)),
    ]);
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.dark);

    container.read(themeModeProvider.notifier).toggle(Brightness.dark);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
  });
}
