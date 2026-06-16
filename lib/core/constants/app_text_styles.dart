import 'package:flutter/material.dart';

/// DentLink tipografi sistemi — Stitch "Clinical Glass" tasarımından.
///
/// Çift font ailesi yaklaşımı:
/// - **Outfit**: Başlıklar ve büyük metinler (geometrik, modern, cerrahi)
/// - **Plus Jakarta Sans**: Gövde ve etiketler (geniş aperture, okunabilir)
///
/// Kaynak: Stitch → Dentist Connect - Soft Tech - PRD
abstract final class AppTextStyles {
  static const String fontHeadline = 'Outfit';
  static const String fontBody = 'PlusJakartaSans';

  // ────────────────────────────────────────────
  // Display — Outfit
  // ────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  // ────────────────────────────────────────────
  // Headline — Outfit (Stitch: headline-lg 30px/36px, headline-md 24px/32px)
  // ────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,     // 36px / 30px
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,    // 32px / 24px
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ────────────────────────────────────────────
  // Title — Outfit (Stitch: title-md 18px/24px)
  // ────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,    // 24px / 18px
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // ────────────────────────────────────────────
  // Body — Plus Jakarta Sans (Stitch: body-lg 16px/24px, body-md 14px/20px)
  // ────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,     // 24px / 16px
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,    // 20px / 14px
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ────────────────────────────────────────────
  // Label — Plus Jakarta Sans (Stitch: label-sm 12px/16px, 600, 0.02em)
  // ────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,    // 16px / 12px
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ────────────────────────────────────────────
  // Özel Stiller
  // ────────────────────────────────────────────

  /// Buton metni
  static const TextStyle button = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.5,
  );

  /// Üst bar başlık
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// Tab bar etiketleri
  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  /// Bottom nav etiketleri
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );

  /// Rozet metni
  static const TextStyle badge = TextStyle(
    fontFamily: fontBody,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// İstatistik sayıları (profil vb.)
  static const TextStyle statNumber = TextStyle(
    fontFamily: fontHeadline,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// İstatistik etiketleri
  static const TextStyle statLabel = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );
}
