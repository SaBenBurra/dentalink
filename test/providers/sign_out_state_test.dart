import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:dentlink/providers/following_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

void main() {
  test('çıkış yapınca önceki kullanıcının takip durumu temizlenir (AUTH-2)', () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(MockAuthForTest()),
    ]);
    addTearDown(container.dispose);

    await container.read(authProvider.future);
    container.listen(followingStateProvider, (_, _) {});

    container.read(followingStateProvider.notifier).setFollowStatus('other', true);
    expect(container.read(followingStateProvider), {'other': true});

    await container.read(authProvider.notifier).signOut();

    expect(container.read(followingStateProvider), isEmpty);
  });
}
