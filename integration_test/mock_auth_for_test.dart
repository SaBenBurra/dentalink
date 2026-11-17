import 'dart:async';
import 'dart:io';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/data/repositories/auth_repository.dart';

class MockAuthForTest implements AuthRepository {
  UserModel? _currentUser;

  MockAuthForTest({bool verified = true}) {
    _currentUser = UserModel(
      id: 'mock_test_user_id',
      email: 'test@example.com',
      fullName: 'Test User',
      username: 'testuser',
      title: UserTitle.ogrenci,
      onboardingCompleted: true,
      // 066: mevcut hesaplar doğrulanmış sayılır; kilit testleri ayrı kullanıcı kurar.
      isVerified: verified,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> sendOtp(String emailOrPhone) async {}

  @override
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    return _currentUser;
  }

  @override
  Future<void> requestContactChange(String emailOrPhone) async {}

  @override
  Future<UserModel?> confirmContactChange(
    String emailOrPhone,
    String otpCode,
  ) async {
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  bool get hasSession => _currentUser != null;

  final _signedOut = StreamController<void>.broadcast();

  /// Sunucunun oturumu düşürmesini taklit eder (AUTH-5).
  void expireSession() {
    _currentUser = null;
    _signedOut.add(null);
  }

  @override
  Stream<void> get signedOut => _signedOut.stream;

  @override
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
  }) async {
    return _currentUser!;
  }
}
