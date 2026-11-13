import '../models/app_config.dart';

/// Sürüm kontrolü ayarı (migration 062); oturum açmadan da okunur.
abstract class AppConfigRepository {
  /// [platform] `android` ya da `ios`. Satır yoksa null.
  Future<AppConfig?> fetch(String platform);
}
