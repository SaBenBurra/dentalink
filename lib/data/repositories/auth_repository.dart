import '../models/user_model.dart';

/// Kimlik doğrulama repository arayüzü.
/// Faz 3'te MockAuthRepository → SupabaseAuthRepository ile swap edilir.
abstract class AuthRepository {
  /// Oturumu açık olan kullanıcıyı döndürür. Oturum yoksa null.
  Future<UserModel?> getCurrentUser();

  /// E-posta + şifre ile oturum açar.
  Future<UserModel> signInWithEmail(String email, String password);

  /// Yeni kullanıcı kaydı (e-posta + şifre).
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String username,
  });

  /// Oturumu kapatır.
  Future<void> signOut();
}
