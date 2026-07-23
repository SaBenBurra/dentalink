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
  Future<void> sendOtp(String emailOrPhone) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock: OTP gönderildi kabul edilir.
  }

  @override
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (otpCode.length < 4) {
      throw Exception('Geçersiz doğrulama kodu');
    }

    final normalized = emailOrPhone.trim().toLowerCase();
    try {
      _currentUser = MockDatasource.users.firstWhere(
        (u) =>
            (u.email?.toLowerCase() ?? '') == normalized ||
            u.phone == normalized,
      );
    } catch (_) {
      _currentUser = MockDatasource.userById(MockDatasource.currentUserId);
    }

    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}
