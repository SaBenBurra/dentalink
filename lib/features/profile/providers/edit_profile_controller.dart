import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/enums.dart';

/// Profil düzenleme işlemlerini yöneten Riverpod controller.
///
/// SRP uyumluluğu için UI bileşenlerinden profil kaydetme iş mantığı
/// ve form bekleme durumları (loading state) buraya taşınmıştır.
final editProfileProvider =
    AutoDisposeAsyncNotifierProvider<EditProfileController, void>(() {
  return EditProfileController();
});

class EditProfileController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Başlangıç durumu boş
  }

  /// Profil değişikliklerini kaydeder.
  Future<void> saveProfile({
    required String fullName,
    required UserTitle title,
    String? bio,
    String? university,
    String? city,
    String? experience,
    String? workplace,
  }) async {
    state = const AsyncLoading();
    try {
      // TODO: Faz 3'te userRepository / authRepository üzerinden backend'e gönderilecek.
      // Şimdilik mock bekleme süresi:
      await Future.delayed(const Duration(seconds: 1));
      
      // authProvider'a gidip local state de güncellenebilir.
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
