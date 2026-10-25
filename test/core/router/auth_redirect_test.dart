import 'package:dentlink/core/router/app_router.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final user = UserModel(
    id: 'u1',
    fullName: 'Test',
    username: 'test',
    title: UserTitle.ogrenci,
    createdAt: DateTime(2026),
  );

  String? go(
    String location, {
    bool session = true,
    bool hold = false,
    required AsyncValue<UserModel?> auth,
  }) =>
      resolveAuthRedirect(
        location: location,
        hasSession: session,
        hold: hold,
        auth: auth,
      );

  group('resolveAuthRedirect', () {
    test('oturum yoksa korumalı sayfadan /login\'e', () {
      expect(go('/feed', session: false, auth: const AsyncData(null)), '/login');
      expect(go('/auth-error', session: false, auth: const AsyncData(null)), '/login');
      expect(go('/login', session: false, auth: const AsyncData(null)), isNull);
    });

    test('profil yüklenirken veya hold aktifken karar verilmez', () {
      expect(go('/login', auth: const AsyncLoading()), isNull);
      expect(go('/login', hold: true, auth: const AsyncData(null)), isNull);
    });

    test('profil yükleme HATASI kayıt ekranına değil hata ekranına götürür (AUTH-1)', () {
      final err = AsyncError<UserModel?>(Exception('network'), StackTrace.empty);
      expect(go('/login', auth: err), '/auth-error');
      expect(go('/feed', auth: err), '/auth-error');
      expect(go('/auth-error', auth: err), isNull);
      // Kayıt insert'ü hatası kayıt ekranında gösterilir.
      expect(go('/register', auth: err), isNull);
    });

    test('profil yoksa /register', () {
      expect(go('/feed', auth: const AsyncData(null)), '/register');
      expect(go('/register', auth: const AsyncData(null)), isNull);
    });

    test('kayıtlı kullanıcı auth ekranlarından /feed\'e, diğer sayfalarda kalır', () {
      expect(go('/login', auth: AsyncData(user)), '/feed');
      expect(go('/register', auth: AsyncData(user)), '/feed');
      expect(go('/auth-error', auth: AsyncData(user)), '/feed');
      expect(go('/profile/abc', auth: AsyncData(user)), isNull);
    });
  });
}
