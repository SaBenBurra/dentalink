/// Platformun sürüm ayarı (migration 062, `app_config`).
class AppConfig {
  const AppConfig({
    required this.minSupportedVersion,
    required this.latestVersion,
    this.storeUrl,
  });

  final String minSupportedVersion;
  final String latestVersion;

  /// iOS App Store kaydı açılana kadar null.
  final String? storeUrl;

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    minSupportedVersion: json['min_supported_version'] as String,
    latestVersion: json['latest_version'] as String,
    storeUrl: json['store_url'] as String?,
  );
}
