import 'dart:io';
import '../models/enums.dart';
import '../models/user_model.dart';

/// Kimlik doğrulama repository arayüzü.
/// OTP (şifresiz) tabanlı kimlik doğrulama akışı:
///   1. sendOtp → e-posta veya telefona tek kullanımlık kod gönderir
///   2. verifyOtp → gönderilen kodu doğrular, oturum açar
abstract class AuthRepository {
  /// Oturumu açık olan kullanıcıyı döndürür. Oturum yoksa null.
  /// Profil (public.users) mevcutsa UserModel döner, yoksa null.
  Future<UserModel?> getCurrentUser();

  /// E-posta veya telefon numarasına OTP kodu gönderir.
  /// [emailOrPhone] — geçerli bir e-posta veya telefon numarası.
  /// Cooldown aktifse [OtpCooldownException] fırlatır.
  Future<void> sendOtp(String emailOrPhone);

  /// Gönderilen OTP kodunu doğrular ve oturum açar.
  /// [emailOrPhone] — OTP gönderilen adres/numara.
  /// [otpCode] — kullanıcının girdiği doğrulama kodu.
  /// Profili olan kullanıcı → UserModel döner.
  /// Yeni kullanıcı (profili yok) → null döner, kayıt ekranına yönlendirilir.
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode);

  /// Oturumu kapatır.
  Future<void> signOut();

  /// Oturumun açık olup olmadığını kontrol eder (profil olmasa bile).
  bool get hasSession;

  /// Kayıt bilgilerini veritabanına yazar ve profili oluşturur.
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
  });
}
