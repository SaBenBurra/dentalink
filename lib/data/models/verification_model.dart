// Doğrulama isteği (mezuniyet ya da öğrenci belgesi) — `verification_requests` (065).

import 'dart:typed_data';

import 'enums.dart';

/// `verification-docs` bucket'ının file_size_limit'i (065).
const maxVerificationDocBytes = 5 * 1024 * 1024;

/// PDF imzası (`%PDF`): bucket içerik türünü dosyaya bakmadan kabul eder,
/// uzantısı .pdf olan başka bir dosya panelde açılmasın.
bool looksLikePdf(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

enum VerificationStatus {
  pending,
  approved,
  rejected;

  static VerificationStatus parse(String? value) =>
      VerificationStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => VerificationStatus.pending,
      );
}

/// `verification_requests.doc_type`; unvandan seçilir. Diploma ve öğrenci
/// kimlik kartı kabul edilmez.
enum VerificationDocType {
  graduationCertificate('graduation_certificate'),
  studentCertificate('student_certificate');

  const VerificationDocType(this.dbValue);
  final String dbValue;

  static VerificationDocType forTitle(UserTitle title) =>
      title == UserTitle.ogrenci ? studentCertificate : graduationCertificate;
}

class VerificationRequest {
  final String id;
  final VerificationStatus status;

  /// Ret gerekçesi (onayda isteğe bağlı not).
  final String? reason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const VerificationRequest({
    required this.id,
    required this.status,
    this.reason,
    required this.createdAt,
    this.reviewedAt,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) =>
      VerificationRequest(
        id: json['id'] as String,
        status: VerificationStatus.parse(json['status'] as String?),
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        reviewedAt: json['reviewed_at'] == null
            ? null
            : DateTime.parse(json['reviewed_at'] as String).toLocal(),
      );
}
