import 'dart:typed_data';

import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/verification_model.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/data/repositories/verification_repository.dart';
import 'package:dentigo/features/settings/providers/verification_provider.dart';
import 'package:dentigo/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/mock_auth_for_test.dart';

class _Repo implements VerificationRepository {
  _Repo(this.latest);

  VerificationRequest? latest;
  final submitted = <(Uint8List, VerificationDocType, bool)>[];

  @override
  Future<VerificationRequest?> getLatest() async => latest;

  @override
  Future<VerificationRequest> submit(
    Uint8List bytes,
    VerificationDocType type, {
    bool pdf = false,
  }) async {
    submitted.add((bytes, type, pdf));
    return VerificationRequest(
      id: 'r2',
      status: VerificationStatus.pending,
      createdAt: DateTime(2026),
    );
  }
}

VerificationRequest _request(VerificationStatus status, {String? reason}) =>
    VerificationRequest(
      id: 'r1',
      status: status,
      reason: reason,
      createdAt: DateTime(2026),
    );

void main() {
  Future<ProviderContainer> start(_Repo repo) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthForTest(verified: false)),
        verificationRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    container.listen(verificationProvider, (_, _) {});
    await container.read(verificationProvider.future);
    return container;
  }

  test('gönderince durum bekleyen olur', () async {
    final repo = _Repo(
      _request(VerificationStatus.rejected, reason: 'Okunmuyor'),
    );
    final container = await start(repo);

    await container
        .read(verificationProvider.notifier)
        .submit(
          Uint8List.fromList([1, 2]),
          VerificationDocType.studentCertificate,
          pdf: true,
        );

    expect(repo.submitted.single.$2, VerificationDocType.studentCertificate);
    expect(repo.submitted.single.$3, isTrue);
    expect(
      container.read(verificationProvider).requireValue?.status,
      VerificationStatus.pending,
    );
  });

  test('onaylı istek oturumdaki profili doğrulanmış yapar', () async {
    final container = await start(_Repo(_request(VerificationStatus.approved)));
    expect(container.read(currentUserProvider)?.isVerified, isTrue);
  });

  test('ret profili değiştirmez', () async {
    final container = await start(
      _Repo(_request(VerificationStatus.rejected, reason: 'x')),
    );
    expect(container.read(currentUserProvider)?.isVerified, isFalse);
  });

  test(
    'model: bilinmeyen durum bekleyen sayılır, tarih yerel saate çevrilir',
    () {
      final r = VerificationRequest.fromJson({
        'id': 'r1',
        'status': 'weird',
        'reason': null,
        'created_at': '2026-11-17T10:00:00Z',
        'reviewed_at': null,
      });
      expect(r.status, VerificationStatus.pending);
      expect(r.createdAt.isUtc, isFalse);
      expect(r.reviewedAt, isNull);
    },
  );

  test(
    'belge türü unvandan: öğrenci → öğrenci belgesi, diğerleri → mezuniyet belgesi',
    () {
      expect(
        VerificationDocType.forTitle(UserTitle.ogrenci),
        VerificationDocType.studentCertificate,
      );
      expect(
        VerificationDocType.forTitle(UserTitle.endodontist),
        VerificationDocType.graduationCertificate,
      );
      expect(
        VerificationDocType.studentCertificate.dbValue,
        'student_certificate',
      );
    },
  );

  test('PDF imzası %PDF ile başlayan dosyayı tanır', () {
    expect(looksLikePdf(Uint8List.fromList('%PDF-1.7'.codeUnits)), isTrue);
    expect(looksLikePdf(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), isFalse);
    expect(looksLikePdf(Uint8List.fromList('%PD'.codeUnits)), isFalse);
  });
}
