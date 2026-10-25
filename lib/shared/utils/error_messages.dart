import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException, PostgrestException;

import '../../core/error/app_failures.dart';
import '../../core/l10n/generated/app_localizations.dart';

/// Hatayı kullanıcıya gösterilecek metne çevirir. Ham `Exception: ...` metni
/// asla UI'a çıkmaz.
String getErrorMessage(AppLocalizations l10n, Object e) {
  if (e is AppFailure) {
    return switch (e) {
      AuthRequiredFailure()     => l10n.errorAuthRequired,
      PermissionDeniedFailure() => l10n.errorPermissionDenied,
      NotFoundFailure()         => l10n.errorNotFound,
      NetworkFailure()          => l10n.networkError,
      ValidationFailure()       => l10n.errorValidation,
      ConflictFailure()         => l10n.errorConflict,
      ServerFailure()           => l10n.errorServer,
    };
  }
  // guardSupabase'den geçmeyen repository çağrıları için.
  if (e is SocketException || e is AuthRetryableFetchException) {
    return l10n.networkError;
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
