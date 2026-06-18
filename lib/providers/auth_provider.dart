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
// Auth State Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithEmail(email, password),
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
