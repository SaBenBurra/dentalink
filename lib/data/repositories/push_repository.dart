/// Cihaz push token'ını kullanıcıya bağlar (migration 027).
abstract class PushRepository {
  Future<void> register(String token, String platform);

  Future<void> unregister(String token);
}
