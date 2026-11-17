/// Cihaz push token'ını kullanıcıya bağlar (migration 027).
abstract class PushRepository {
  Future<void> register(String token, String platform);

  Future<void> unregister(String token);

  /// Bu cihaz panel duyurularını alsın mı (067, sunucu süzer).
  Future<void> setAnnouncements(String token, bool enabled);
}
