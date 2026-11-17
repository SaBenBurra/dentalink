import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/verification_model.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../providers/auth_provider.dart';

/// Kullanıcının en son doğrulama isteği; hiç göndermediyse null.
class VerificationNotifier
    extends AutoDisposeAsyncNotifier<VerificationRequest?> {
  @override
  Future<VerificationRequest?> build() async {
    final uid = ref.watch(authProvider.select((s) => s.valueOrNull?.id));
    if (uid == null) return null;
    final latest = await ref.read(verificationRepositoryProvider).getLatest();
    // Onay uygulama açıkken geldiyse oturumdaki profil eski kalır. İsteğe değil
    // profile bakılır: doğrulama sonradan kaldırılırsa (068) istek yine onaylıdır.
    if (latest?.status == VerificationStatus.approved &&
        !(ref.read(currentUserProvider)?.isVerified ?? false)) {
      await ref.read(authProvider.notifier).refreshProfile();
    }
    return latest;
  }

  Future<void> submit(
    Uint8List bytes,
    VerificationDocType type, {
    bool pdf = false,
  }) async {
    final request = await ref
        .read(verificationRepositoryProvider)
        .submit(bytes, type, pdf: pdf);
    state = AsyncData(request);
  }
}

final verificationProvider =
    AsyncNotifierProvider.autoDispose<
      VerificationNotifier,
      VerificationRequest?
    >(VerificationNotifier.new);
