import '../datasources/mock_datasource.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';
import 'otp_send_limiter.dart';

/// Sahte OTP kimlik doğrulama. Faz 3'te SupabaseAuthRepository ile swap edilir.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    Duration otpCooldown = const Duration(seconds: 60),
    int maxDistinctDestinations = 2,
  }) : _limiter = OtpSendLimiter(
          cooldown: otpCooldown,
          maxDistinctDestinations: maxDistinctDestinations,
          persist: false,
        );

  static const _delay = Duration(milliseconds: 400);

  final OtpSendLimiter _limiter;

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
    final destination = emailOrPhone.trim().toLowerCase();
    await _limiter.ensureLoaded();
    final blocked = _limiter.check(destination);
    if (blocked != null) throw blocked;

    await Future.delayed(const Duration(milliseconds: 800));
    await _limiter.recordSuccess(destination);
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
