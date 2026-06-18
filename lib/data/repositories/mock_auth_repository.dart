import '../datasources/mock_datasource.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// Sahte kimlik doğrulama. Faz 3'te SupabaseAuthRepository ile swap edilir.
class MockAuthRepository implements AuthRepository {
  static const _delay = Duration(milliseconds: 400);

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(_delay);
    // Mock oturumda u1 her zaman oturum açmış kabul edilir.
    return MockDatasource.userById(MockDatasource.currentUserId);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    await Future.delayed(_delay);
    // Mock: email'e göre kullanıcı bul, yoksa u1 döndür.
    try {
      return MockDatasource.users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return MockDatasource.userById(MockDatasource.currentUserId);
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    await Future.delayed(_delay);
    // Mock: kayıt sonrası u1 döndür.
    return MockDatasource.userById(MockDatasource.currentUserId);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock: hiçbir şey yapmaz.
  }
}
