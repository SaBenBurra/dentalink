import 'dart:io';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/repositories/auth_repository.dart';

class MockAuthForTest implements AuthRepository {
  UserModel? _currentUser;

  MockAuthForTest() {
    _currentUser = UserModel(
      id: 'mock_test_user_id',
      email: 'test@example.com',
      fullName: 'Test User',
      username: 'testuser',
      title: UserTitle.ogrenci,
      onboardingCompleted: true,
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
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  bool get hasSession => _currentUser != null;

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
