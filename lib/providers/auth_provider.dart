import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_failures.dart';
import '../core/utils/string_utils.dart';
import '../domain/enums/enums.dart';
import '../data/models/user_model.dart';
import '../data/providers/repository_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth State Notifier — OTP tabanlı şifresiz kimlik doğrulama
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repo = ref.read(authRepositoryProvider);
    // Token iptal edilir ya da süresi dolarsa: state null → router login'e,
    // kullanıcıya özel provider'lar temizlenir (AUTH-5).
    final sub = repo.signedOut.listen((_) => state = const AsyncData(null));
    ref.onDispose(sub.cancel);

    // Uygulama başlatıldığında mevcut oturumu kontrol et
    return repo.getCurrentUser();
  }

  /// OTP kodu gönderir.
  Future<void> sendOtp(String emailOrPhone) async {
    await ref.read(authRepositoryProvider).sendOtp(emailOrPhone);
  }

  /// OTP kodunu doğrular ve oturum açar.
  /// Profili olan kullanıcı → UserModel döner (state güncellenir).
  /// Yeni kullanıcı → null döner (kayıt ekranına yönlendirilir).
  /// Doğrulama başarısız olursa hata fırlatır — çağıran yakalamalı.
  ///
  /// NOT: Burada [AsyncValue.guard] KULLANILMAZ; çünkü guard hatayı yutup
  /// state'i AsyncError yapıyor ama fırlatmıyordu. Bu durumda login ekranı
  /// hatayı fark edemeyip kullanıcıyı oturum açılmadan kayıt ekranına
  /// yönlendiriyor, ardından "Oturum bulunamadı" hatası çıkıyordu.
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .verifyOtp(emailOrPhone, otpCode);
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> completeRegistration({
    required String fullName,
    required UserTitle title,
    String? bio,
    String? university,
    String? city,
    String? workplace,
    int? experienceYears,
    File? avatarFile,
  }) async {
    state = const AsyncLoading();
    try {
      // Kullanıcı adı çakışırsa (23505 users_username_key) yeni ekle tekrar dene.
      for (var attempt = 1;; attempt++) {
        try {
          final user = await ref.read(authRepositoryProvider).completeRegistration(
            fullName: fullName,
            username: generateUsername(fullName),
            title: title,
            bio: bio,
            university: university,
            city: city,
            workplace: workplace,
            experienceYears: experienceYears,
            avatarFile: avatarFile,
          );
          state = AsyncData(user);
          return;
        } on ConflictFailure catch (e) {
          final usernameTaken =
              e.message.contains('username');
          if (!usernameTaken || attempt >= 3) rethrow;
        }
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
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

/// OTP başarı animasyonu sırasında router'ın erken yönlendirmesini engeller.
///
/// `verifyOtp` auth state'i güncellediğinde profil kontrolü tetiklenir; bu
/// bayrak true iken redirect bekletilir, animasyon bitince login ekranı
/// kendisi `/feed` veya `/register`'a gider.
final authRedirectHoldProvider = StateProvider<bool>((ref) => false);
