import 'package:dentigo/providers/welcome_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('"Hoş geldin" görüldü bilgisi kullanıcıya özel ve kalıcı', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
      overrides: [
        welcomedUsersProvider.overrideWith(() => WelcomedUsersNotifier(prefs)),
      ],
    );

    final first = make();
    first.read(welcomedUsersProvider.notifier).markWelcomed('u1');
    expect(first.read(welcomedUsersProvider), {'u1'});
    first.dispose();

    final again = make();
    expect(again.read(welcomedUsersProvider).contains('u1'), isTrue);
    expect(again.read(welcomedUsersProvider).contains('u2'), isFalse);
    again.dispose();
  });
}
