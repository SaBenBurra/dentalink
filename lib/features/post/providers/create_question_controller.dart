import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Yeni soru formunu gönderir.
  ///
  /// Soru gönderilerinde görsel opsiyoneldir ve şu anki implementasyonda
  /// desteklenmez (ileride eklenebilir). Etiketler veritabanına upsert edilir.
  Future<void> submit({
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(createPostRepositoryProvider);

      await repo.createQuestion(
        title: title,
        content: content,
        tags: tags,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
