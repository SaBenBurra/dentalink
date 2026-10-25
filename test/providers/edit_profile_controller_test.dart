import 'dart:io';

import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/user_repository.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/features/profile/providers/edit_profile_controller.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

class _FakeUserRepo implements UserRepository {
  final calls = <String>[];
  int? experienceYears;
  String? fullName;

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async {
    calls.add('upload:$userId');
    return 'url';
  }

  @override
  Future<void> updateProfile(
    String userId, {
    String? fullName,
    UserTitle? title,
    String? bio,
    String? university,
    String? city,
    int? experienceYears,
    String? workplace,
  }) async {
    calls.add('update:$userId');
    this.experienceYears = experienceYears;
    this.fullName = fullName;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(MockAuthForTest auth, _FakeUserRepo repo) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(auth),
    userRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);
  container.listen(editProfileProvider, (_, _) {});
  return container;
}

void main() {
  test('seçilen avatar profil kaydedilmeden önce yüklenir (BUG-16)', () async {
    final repo = _FakeUserRepo();
    final container = _container(MockAuthForTest(), repo);
    await container.read(authProvider.future);

    await container.read(editProfileProvider.notifier).saveProfile(
          fullName: '  A  ',
          title: UserTitle.ogrenci,
          experience: ' 3 ',
          avatarFile: File('a.jpg'),
        );

    expect(container.read(editProfileProvider).hasError, isFalse);
    expect(repo.calls, ['upload:mock_test_user_id', 'update:mock_test_user_id']);
    expect(repo.experienceYears, 3);
    expect(repo.fullName, 'A'); // UX-10
  });

  test('oturum yoksa "başarılı" dönmez (BUG-16)', () async {
    final auth = MockAuthForTest();
    await auth.signOut();
    final container = _container(auth, _FakeUserRepo());
    await container.read(authProvider.future);

    await container
        .read(editProfileProvider.notifier)
        .saveProfile(fullName: 'A', title: UserTitle.ogrenci);

    expect(container.read(editProfileProvider).error, isA<AuthRequiredFailure>());
  });
}
