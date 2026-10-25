import 'dart:io';

import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

/// İlk [conflicts] denemede verilen kısıtla 23505 (ConflictFailure) fırlatır.
class _ConflictingAuth extends MockAuthForTest {
  _ConflictingAuth(this.conflicts, this.constraint);
  final int conflicts;
  final String constraint;
  final usernames = <String>[];

  @override
  Future<UserModel> completeRegistration({
    required String fullName,
    required String username,
    required UserTitle title,
    String? bio,
    String? university,
    String? city,
    String? workplace,
    int? experienceYears,
    File? avatarFile,
  }) async {
    usernames.add(username);
    if (usernames.length <= conflicts) {
      throw ConflictFailure('duplicate key value violates unique constraint "$constraint"');
    }
    return super.completeRegistration(fullName: fullName, username: username, title: title);
  }
}

void main() {
  Future<_ConflictingAuth> register(int conflicts, String constraint) async {
    final repo = _ConflictingAuth(conflicts, constraint);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    await container
        .read(authProvider.notifier)
        .completeRegistration(fullName: 'Ayşe Yılmaz', title: UserTitle.ogrenci)
        .catchError((_) {});
    return repo;
  }

  test('kullanıcı adı çakışırsa yeni adla en fazla 3 kez denenir (AUTH-4)', () async {
    expect((await register(1, 'users_username_key')).usernames, hasLength(2));
    expect((await register(5, 'users_username_key')).usernames, hasLength(3));
  });

  test('başka bir çakışma yeniden denenmez', () async {
    expect((await register(1, 'users_pkey')).usernames, hasLength(1));
  });
}
