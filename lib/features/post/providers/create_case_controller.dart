import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  Future<void> submit({
    required String title,
    required String content,
    required String branch,
    required List<String> imageUrls,
    required List<String> tags,
  }) async {
    state = const AsyncLoading();
    try {
      // TODO: Faz 3'te postRepository üzerinden backend'e gönderilecek.
      // Şimdilik mock bekleme süresi:
      await Future.delayed(const Duration(seconds: 1));
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
