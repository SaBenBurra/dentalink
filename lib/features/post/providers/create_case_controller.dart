import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/case_treatment.dart';
import '../../../core/utils/media_prepare.dart';
import '../../../data/models/post_model.dart';
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
  /// [media] kullanıcının seçip sıraladığı görseller ve video. Görseller
  /// `post-images`'a, video 720p'ye sıkıştırılıp `post-videos`'a yüklenir,
  /// ardından post ve ilişkili kayıtlar veritabanına yazılır.
  Future<PostModel?> submit({
    required String title,
    required String content,
    required List<CaseTreatment> treatments,
    required List<PickedMedia> media,
    required List<String> tags,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(createPostRepositoryProvider);

      final post = await repo.createCase(
        title: title,
        content: content,
        treatments: treatments,
        media: await prepareMedia(media),
        tags: tags,
      );

      state = const AsyncData(null);
      return post;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
