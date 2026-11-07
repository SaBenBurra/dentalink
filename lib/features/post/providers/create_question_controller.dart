import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/media_prepare.dart';
import '../../../data/models/post_model.dart';
import '../../../data/providers/repository_providers.dart';

/// Soru oluşturma ekranının durumunu ve mantığını yöneten kontrolcü.
/// (SRP uyumlu: UI katmanından backend ve validasyon mantığını ayırır).
final createQuestionProvider =
    AutoDisposeAsyncNotifierProvider<CreateQuestionController, void>(() {
      return CreateQuestionController();
    });

class CreateQuestionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Başlangıç durumu boş
  }

  /// Yeni forum gönderisini gönderir. Görsel ve video isteğe bağlıdır
  /// (vaka ile aynı sıkıştırma). Etiketler veritabanına upsert edilir.
  Future<PostModel?> submit({
    required String title,
    required String content,
    List<PickedMedia> media = const [],
    required List<String> tags,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(createPostRepositoryProvider);

      final post = await repo.createQuestion(
        title: title,
        content: content,
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
