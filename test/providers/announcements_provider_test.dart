import 'package:dentigo/providers/push_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ProviderContainer container(SharedPreferences prefs) {
    final c = ProviderContainer(
      overrides: [
        announcementsEnabledProvider.overrideWith(
          () => AnnouncementsNotifier(prefs),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('varsayılan açık, kapatma kalıcı', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = container(prefs);
    expect(first.read(announcementsEnabledProvider), isTrue);
    // Firebase yok (firebaseReadyProvider false): pushProvider null, abonelik çağrısı atlanır.
    first.read(announcementsEnabledProvider.notifier).set(false);
    expect(first.read(announcementsEnabledProvider), isFalse);

    expect(container(prefs).read(announcementsEnabledProvider), isFalse);
  });
}
