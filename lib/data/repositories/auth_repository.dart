import '../models/user_model.dart';

/// Kimlik doğrulama repository arayüzü.
/// OTP (şifresiz) tabanlı kimlik doğrulama akışı:
///   1. sendOtp → e-posta veya telefona tek kullanımlık kod gönderir
///   2. verifyOtp → gönderilen kodu doğrular, oturum açar
///
/// Faz 3'te MockAuthRepository → SupabaseAuthRepository ile swap edilir.
abstract class AuthRepository {
  /// Oturumu açık olan kullanıcıyı döndürür. Oturum yoksa null.
  Future<UserModel?> getCurrentUser();

  /// E-posta veya telefon numarasına OTP kodu gönderir.
  /// [emailOrPhone] — geçerli bir e-posta veya telefon numarası.
  /// Dönen değer: kullanıcının daha önce kayıtlı olup olmadığını belirtir.
  Future<bool> sendOtp(String emailOrPhone);

  /// Gönderilen OTP kodunu doğrular ve oturum açar.
  /// [emailOrPhone] — OTP gönderilen adres/numara.
  /// [otpCode] — kullanıcının girdiği doğrulama kodu.
  /// Başarılı doğrulama sonrası kullanıcıyı döndürür.
  /// Kayıtlı olmayan kullanıcı için yeni hesap oluşturulur (Supabase tarafında).
  Future<UserModel> verifyOtp(String emailOrPhone, String otpCode);

  /// Oturumu kapatır.
  Future<void> signOut();
}
