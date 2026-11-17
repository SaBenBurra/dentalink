import 'dart:typed_data';

import '../models/verification_model.dart';

/// Kullanıcının doğrulama istekleri (065): mezuniyet ya da öğrenci belgesi.
/// Onay ve ret admin panelinde.
abstract class VerificationRepository {
  /// En son istek; hiç göndermediyse null.
  Future<VerificationRequest?> getLatest();

  /// Belgeyi (JPEG fotoğraf ya da [pdf]) yükler ve bekleyen istek açar.
  Future<VerificationRequest> submit(
    Uint8List bytes,
    VerificationDocType type, {
    bool pdf = false,
  });
}
