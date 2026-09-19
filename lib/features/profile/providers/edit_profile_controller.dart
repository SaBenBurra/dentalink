import 'dart:async';
import 'dart:io' as dart_io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/enums/enums.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../providers/auth_provider.dart';

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
    dart_io.File? avatarFile,
  }) async {
    state = const AsyncLoading();
    try {
      final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (currentUserId != null) {
        if (avatarFile != null) {
          await ref.read(userRepositoryProvider).uploadAvatar(currentUserId, avatarFile);
        }

        await ref.read(userRepositoryProvider).updateProfile(
          currentUserId,
          fullName: fullName,
          title: title,
          bio: bio,
          university: university,
          city: city,
          experienceYears: experience != null && experience.isNotEmpty ? int.tryParse(experience) : null,
          workplace: workplace,
        );
        
        // Kullanıcı profilinin UI'da güncellenmesi için provider'ı invalidate et
        ref.invalidate(authProvider);
      }
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
