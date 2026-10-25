/// Profil alanlarının uzunluk sınırları; DB CHECK'leri migration 022'de (UX-8).
abstract final class ProfileLimits {
  static const fullName = 60;
  static const bio = 300;
  static const text = 100; // üniversite, şehir, klinik
  static const experienceDigits = 2; // 0–70
}
