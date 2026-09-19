import '../../core/error/app_failures.dart';

/// AppFailure tiplerine göre kullanıcı dostu, yerelleştirilebilir (l10n) mesajlar döndürür.
String getErrorMessage(Object e) {
  if (e is! AppFailure) return 'Beklenmeyen bir hata oluştu.';
  return switch (e) {
    AuthRequiredFailure()     => 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
    PermissionDeniedFailure() => 'Bu işlem için yetkiniz yok.',
    NotFoundFailure()         => 'İçerik bulunamadı veya silinmiş.',
    NetworkFailure()          => 'İnternet bağlantınızı kontrol edin.',
    ValidationFailure()       => 'Girdiğiniz içerik geçerli değil.',
    ServerFailure()           => 'Bir sorun oluştu, lütfen tekrar deneyin.',
  };
}
