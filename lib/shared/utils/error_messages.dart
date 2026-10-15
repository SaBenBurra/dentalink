import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException, PostgrestException;

import '../../core/error/app_failures.dart';

/// Hatayı kullanıcıya gösterilecek metne çevirir. Ham `Exception: ...` metni
/// asla UI'a çıkmaz.
///
/// shortcut: metinler TR sabit; l10n'a taşıma ROADMAP Faz 3 (UX-12).
String getErrorMessage(Object e) {
  if (e is AppFailure) {
    return switch (e) {
      AuthRequiredFailure()     => 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
      PermissionDeniedFailure() => 'Bu işlem için yetkiniz yok.',
      NotFoundFailure()         => 'İçerik bulunamadı veya silinmiş.',
      NetworkFailure()          => 'İnternet bağlantınızı kontrol edin.',
      ValidationFailure()       => 'Girdiğiniz içerik geçerli değil.',
      ServerFailure()           => 'Bir sorun oluştu, lütfen tekrar deneyin.',
    };
  }
  // guardSupabase'den geçmeyen repository çağrıları için.
  if (e is SocketException || e is AuthRetryableFetchException) {
    return 'İnternet bağlantınızı kontrol edin.';
  }
  if (e is PostgrestException && e.code == '42501') {
    return 'Bu işlem için yetkiniz yok.';
  }
  return 'Beklenmeyen bir hata oluştu.';
}
