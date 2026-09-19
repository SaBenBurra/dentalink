import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/enums.dart';
import '../../../data/providers/repository_providers.dart';

/// Vaka oluşturma ekranının durumunu ve mantığını yöneten kontrolcü.
/// (SRP uyumlu: UI katmanından backend ve validasyon mantığını ayırır).
final createCaseProvider =
    AutoDisposeAsyncNotifierProvider<CreateCaseController, void>(() {
  return CreateCaseController();
});

class CreateCaseController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Başlangıç durumu boş
  }

  /// Yeni vaka formunu gönderir.
  ///
  /// [imageFiles] kullanıcının cihazından seçtiği ham görsel dosyaları.
  /// Görseller Supabase Storage'a (`post-images` bucket'ı) yüklenir,
  /// ardından post ve ilişkili kayıtlar veritabanına yazılır.
  Future<void> submit({
    required String title,
    required String content,
    required DentalBranch branch,
    required List<File> imageFiles,
    required List<String> tags,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(createPostRepositoryProvider);

      await repo.createCase(
        title: title,
        content: content,
        branch: branch,
        imageFiles: imageFiles,
        tags: tags,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
