import 'package:dentlink/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(binding.platformDispatcher.clearLocalesTestValue);

  ProviderContainer containerWith(SharedPreferences prefs) {
    final container = ProviderContainer(
      overrides: [
        localeModeProvider.overrideWith(() => LocaleModeNotifier(prefs)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('seçim yoksa cihaz dili; seçilen dil kalıcı', () async {
    binding.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = containerWith(prefs);
    expect(first.read(localeModeProvider), const Locale('tr'));
    expect(prefs.getString('locale'), isNull); // cihaz dili kaydedilmez

    first.read(localeModeProvider.notifier).setLocale(const Locale('en'));
    expect(prefs.getString('locale'), 'en');

    // Yeniden açılış: cihaz Türkçe olsa da seçilen dil gelir.
    expect(containerWith(prefs).read(localeModeProvider), const Locale('en'));
  });

  test('seçim yokken cihaz dili değişirse sonraki açılış onu izler', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    binding.platformDispatcher.localesTestValue = const [Locale('de')];
    expect(containerWith(prefs).read(localeModeProvider), const Locale('en'));

    binding.platformDispatcher.localesTestValue = const [Locale('tr')];
    expect(containerWith(prefs).read(localeModeProvider), const Locale('tr'));
  });
}
