import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthApiException, AuthRetryableFetchException, PostgrestException;

import '../../core/error/app_failures.dart';
import '../../core/l10n/generated/app_localizations.dart';

/// Hatayı kullanıcıya gösterilecek metne çevirir. Ham `Exception: ...` metni
/// asla UI'a çıkmaz.
String getErrorMessage(AppLocalizations l10n, Object e) {
  if (e is AppFailure) {
    return switch (e) {
      AuthRequiredFailure() => l10n.errorAuthRequired,
      PermissionDeniedFailure() => l10n.errorPermissionDenied,
      NotFoundFailure() => l10n.errorNotFound,
      NetworkFailure() => l10n.networkError,
      ValidationFailure() => l10n.errorValidation,
      ConflictFailure() => l10n.errorConflict,
      ServerFailure() => l10n.errorServer,
    };
  }
  // guardSupabase'den geçmeyen repository çağrıları için.
  if (e is SocketException || e is AuthRetryableFetchException) {
    return l10n.networkError;
  }
  // sendOtp ve e-posta/telefon değişimi guardSupabase'den geçmez.
  if (e is AuthApiException) {
    switch (e.code) {
      case 'email_exists' || 'phone_exists':
        return l10n.contactTaken;
      case 'sms_send_failed':
        return l10n.whatsappSendFailed;
    }
    // send-sms hook'u hata kodu taşıyamaz, sebep mesajdadır.
    if (e.message == 'sms_send_failed') return l10n.whatsappSendFailed;
    if (_isRateLimit(e)) return l10n.otpRateLimited;
  }
  // image_picker izin reddi.
  if (e is PlatformException &&
      (e.code == 'camera_access_denied' || e.code == 'photo_access_denied')) {
    return l10n.errorMediaPermission;
  }
  if (e is PostgrestException && e.code == '42501') {
    return l10n.errorPermissionDenied;
  }
  return l10n.unknownError;
}

bool _isRateLimit(AuthApiException e) =>
    e.statusCode == '429' ||
    const {
      'over_sms_send_rate_limit',
      'over_email_send_rate_limit',
      'over_request_rate_limit',
    }.contains(e.code);

/// Kod doğrulama hatası: yalnızca sunucunun reddettiği kod "hatalı" sayılır.
String getOtpErrorMessage(AppLocalizations l10n, Object e) =>
    e is AuthApiException && !_isRateLimit(e)
    ? l10n.otpInvalid
    : getErrorMessage(l10n, e);

/// Kullanıcı aksiyonunu çalıştırır; hata olursa SnackBar ile gösterir.
/// Messenger önceden alınır: öğe listeden düşüp unmount olsa da mesaj görünür.
Future<void> runOrShowError(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  try {
    await action();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
  }
}
