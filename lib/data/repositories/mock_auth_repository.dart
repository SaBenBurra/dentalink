import '../datasources/mock_datasource.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// Sahte OTP kimlik doğrulama. Faz 3'te SupabaseAuthRepository ile swap edilir.
class MockAuthRepository implements AuthRepository {
  static const _delay = Duration(milliseconds: 400);

  /// Son başarılı doğrulama yapan kullanıcıyı tutar (mock oturum).
  UserModel? _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(_delay);
    // Mock oturumda u1 her zaman oturum açmış kabul edilir.
    _currentUser ??= MockDatasource.userById(MockDatasource.currentUserId);
    return _currentUser;
  }

  @override
  Future<bool> sendOtp(String emailOrPhone) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock: kullanıcının kayıtlı olup olmadığını kontrol et
    final normalized = emailOrPhone.trim().toLowerCase();
    final isRegistered =
        MockDatasource.users.any(
          (u) =>
              u.email.toLowerCase() == normalized ||
              u.phone == normalized,
        ) ||
        normalized.contains('test') ||
        normalized.endsWith('@dentlink.com') ||
        normalized == '5551234567';

    // Gerçek uygulamada burada Supabase signInWithOtp çağrılır.
    // Mock'ta sadece kayıt durumunu döndürüyoruz.
    return isRegistered;
  }

  @override
  Future<UserModel> verifyOtp(String emailOrPhone, String otpCode) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Mock: herhangi bir 4+ haneli kod kabul edilir.
    if (otpCode.length < 4) {
      throw Exception('Geçersiz doğrulama kodu');
    }

    // Kayıtlı kullanıcıyı bul, yoksa u1 döndür.
    final normalized = emailOrPhone.trim().toLowerCase();
    try {
      _currentUser = MockDatasource.users.firstWhere(
        (u) =>
            u.email.toLowerCase() == normalized ||
            u.phone == normalized,
      );
    } catch (_) {
      _currentUser = MockDatasource.userById(MockDatasource.currentUserId);
    }

    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}
