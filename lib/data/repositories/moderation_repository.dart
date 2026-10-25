import '../models/enums.dart';
import '../models/user_model.dart';

/// Raporlama ve engelleme (migration 023).
abstract class ModerationRepository {
  /// İçeriği veya kullanıcıyı raporlar. Aynı hedef ikinci kez raporlanırsa
  /// sessizce yok sayılır.
  Future<void> report(
    ReportTarget target,
    String targetId,
    ReportReason reason, {
    String? note,
  });

  /// Kullanıcıyı engeller; iki yöndeki takip DB'de silinir. Zaten engelliyse
  /// sessizce yok sayılır.
  Future<void> blockUser(String userId);

  Future<void> unblockUser(String userId);

  /// Oturumdaki kullanıcının engelledikleri, en son engellenen önce.
  Future<List<UserModel>> getBlockedUsers();
}
