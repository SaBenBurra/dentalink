/// DentLink boyut ve boşluk sabitleri.
///
/// 4px grid sistemi kullanılır.
/// Tüm spacing, radius ve boyut değerleri buradan alınır.
abstract final class AppDimensions {
  // ────────────────────────────────────────────
  // Spacing (4px grid)
  // ────────────────────────────────────────────
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing56 = 56;
  static const double spacing64 = 64;

  // ────────────────────────────────────────────
  // Border Radius
  // ────────────────────────────────────────────
  static const double radiusSmall = 6;
  static const double radiusMedium = 10;
  static const double radiusLarge = 14;
  static const double radiusXLarge = 20;
  static const double radiusRound = 999;

  // ────────────────────────────────────────────
  // Avatar Boyutları
  // ────────────────────────────────────────────
  static const double avatarSmall = 32;
  static const double avatarMedium = 40;
  static const double avatarLarge = 56;
  static const double avatarXLarge = 80;
  static const double avatarProfile = 100;

  // ────────────────────────────────────────────
  // İkon Boyutları
  // ────────────────────────────────────────────
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconDefault = 24;
  static const double iconLarge = 28;
  static const double iconXLarge = 32;

  // ────────────────────────────────────────────
  // Buton Boyutları
  // ────────────────────────────────────────────
  static const double buttonHeight = 48;
  static const double buttonHeightSmall = 36;
  static const double buttonHeightLarge = 56;

  // ────────────────────────────────────────────
  // Kart ve İçerik
  // ────────────────────────────────────────────
  static const double cardPadding = 16;
  static const double cardElevation = 0;
  static const double cardBorderWidth = 1;

  // ────────────────────────────────────────────
  // Input
  // ────────────────────────────────────────────
  static const double inputHeight = 48;
  static const double inputBorderWidth = 1.5;

  // ────────────────────────────────────────────
  // AppBar
  // ────────────────────────────────────────────
  static const double appBarHeight = 56;
  static const double appBarElevation = 0;

  // ────────────────────────────────────────────
  // Bottom Navigation
  // ────────────────────────────────────────────
  static const double bottomNavHeight = 64;

  // ────────────────────────────────────────────
  // Görseller
  // ────────────────────────────────────────────
  static const double imageMaxHeight = 400;
  static const double thumbnailSize = 80;

  // ────────────────────────────────────────────
  // Genel Sınırlamalar
  // ────────────────────────────────────────────
  static const double maxContentWidth = 600;
  static const int maxImagesPerPost = 10;

  // ────────────────────────────────────────────
  // Animasyon Süreleri (ms)
  // ────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
