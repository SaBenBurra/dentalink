import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Provider
// Faz 3'te: MockAuthRepository → SupabaseAuthRepository
// ─────────────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth State Notifier — OTP tabanlı şifresiz kimlik doğrulama
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  /// OTP kodu gönderir.
  /// Dönen değer: kullanıcının daha önce kayıtlı olup olmadığını belirtir.
  Future<bool> sendOtp(String emailOrPhone) async {
    return ref.read(authRepositoryProvider).sendOtp(emailOrPhone);
  }

  /// OTP kodunu doğrular ve oturum açar.
  /// [emailOrPhone] — OTP gönderilen adres/numara.
  /// [otpCode] — kullanıcının girdiği doğrulama kodu.
  Future<void> verifyOtp(String emailOrPhone, String otpCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyOtp(emailOrPhone, otpCode),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

/// Mevcut kullanıcıyı senkron olarak okumak için kısayol.
/// Null dönebilir — widget katmanında null kontrolü yapılmalı.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
