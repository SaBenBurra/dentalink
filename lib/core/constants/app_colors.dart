import 'package:flutter/material.dart';

/// DentLink renk paleti — Stitch "Clinical Glass" tasarım sisteminden.
///
/// Kaynak: Stitch → Dentist Connect - Soft Tech - PRD
/// Tasarım Sistemi: "Dentist Connect Glass"
/// Tema: Medical Teals + Professional Blues + Glassmorphism
abstract final class AppColors {
  // ────────────────────────────────────────────
  // Marka / Birincil (Primary) — Medical Teal
  // ────────────────────────────────────────────
  static const Color primary = Color(0xFF006B5F); // primary-container
  static const Color primaryLight = Color(
    0xFF83D5C6,
  ); // inverse-primary / primary-fixed-dim
  static const Color primaryDark = Color(0xFF005147); // primary (koyu varyant)
  static const Color primarySurface = Color(0xFF9FF2E2); // primary-fixed
  static const Color primaryContainer = Color(
    0xFF95E8D9,
  ); // on-primary-container

  // ────────────────────────────────────────────
  // İkincil (Secondary) — Professional Blue
  // ────────────────────────────────────────────
  static const Color secondary = Color(0xFF085AC0); // secondary
  static const Color secondaryLight = Color(0xFF5B94FD); // secondary-container
  static const Color secondaryDark = Color(
    0xFF004395,
  ); // on-secondary-fixed-variant
  static const Color secondaryContainer = Color(0xFFD8E2FF); // secondary-fixed
  static const Color secondaryOnContainer = Color(
    0xFF002C66,
  ); // on-secondary-container

  // ────────────────────────────────────────────
  // Üçüncül (Tertiary) — Warm Accent
  // ────────────────────────────────────────────
  static const Color tertiary = Color(0xFF7D2E11); // tertiary
  static const Color tertiaryLight = Color(0xFFFFB59D); // tertiary-fixed-dim
  static const Color tertiaryDark = Color(0xFF390B00); // on-tertiary-fixed
  static const Color tertiaryContainer = Color(
    0xFF9C4426,
  ); // tertiary-container
  static const Color tertiaryOnContainer = Color(
    0xFFFFCEBF,
  ); // on-tertiary-container

  // ────────────────────────────────────────────
  // Semantik Renkler
  // ────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color successLight = Color(0xFFDCFCE7); // Green 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color error = Color(0xFFBA1A1A); // Stitch error
  static const Color errorLight = Color(0xFFFFDAD6); // Stitch error-container
  static const Color onError = Color(0xFFFFFFFF); // on-error
  static const Color onErrorContainer = Color(0xFF93000A); // on-error-container
  static const Color info = Color(0xFF085AC0); // Secondary blue
  static const Color infoLight = Color(0xFFD8E2FF); // secondary-fixed

  // ────────────────────────────────────────────
  // Aydınlık Tema (Light) — Stitch Surface Tokens
  // ────────────────────────────────────────────
  static const Color lightBackground = Color(
    0xFFF7FAF8,
  ); // surface / background
  static const Color lightSurface = Color(
    0xFFFFFFFF,
  ); // surface-container-lowest
  static const Color lightSurfaceContainerLow = Color(
    0xFFF1F4F2,
  ); // surface-container-low
  static const Color lightSurfaceContainer = Color(
    0xFFEBEFEC,
  ); // surface-container
  static const Color lightSurfaceContainerHigh = Color(
    0xFFE5E9E7,
  ); // surface-container-high
  static const Color lightSurfaceVariant = Color(
    0xFFE0E3E1,
  ); // surface-variant / surface-container-highest
  static const Color lightSurfaceDim = Color(0xFFD7DBD9); // surface-dim
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFBEC9C5); // outline-variant
  static const Color lightOutline = Color(0xFF6E7976); // outline
  static const Color lightTextPrimary = Color(0xFF0F172A); // text-main
  static const Color lightTextSecondary = Color(0xFF64748B); // text-muted
  static const Color lightTextTertiary = Color(0xFF6E7976); // outline (soft)
  static const Color lightTextOnSurface = Color(0xFF181C1B); // on-surface
  static const Color lightTextOnSurfaceVariant = Color(
    0xFF3E4946,
  ); // on-surface-variant
  static const Color lightTextOnPrimary = Color(0xFFFFFFFF); // on-primary
  static const Color lightIcon = Color(0xFF64748B); // text-muted
  static const Color lightIconActive = Color(0xFF006B5F); // primary

  // ────────────────────────────────────────────
  // Karanlık Tema (Dark) — Stitch inverse tokens
  // ────────────────────────────────────────────
  static const Color darkBackground = Color(
    0xFF181C1B,
  ); // on-background → dark bg
  static const Color darkSurface = Color(0xFF1E2422); // Slate 800 (derived)
  static const Color darkSurfaceVariant = Color(0xFF2D3130); // inverse-surface
  static const Color darkCard = Color(0xFF1E2422);
  static const Color darkDivider = Color(0xFF3E4946); // on-surface-variant
  static const Color darkTextPrimary = Color(0xFFEEF1EF); // inverse-on-surface
  static const Color darkTextSecondary = Color(0xFFBEC9C5); // outline-variant
  static const Color darkTextTertiary = Color(0xFF6E7976); // outline
  static const Color darkTextOnPrimary = Color(0xFFFFFFFF);
  static const Color darkIcon = Color(0xFFBEC9C5); // outline-variant
  static const Color darkIconActive = Color(0xFF83D5C6); // inverse-primary

  // ────────────────────────────────────────────
  // Glassmorphism Özel Renkler
  // ────────────────────────────────────────────
  /// Cam efekti yüzey rengi (60% opaklık beyaz)
  static const Color glassSurface = Color(0x99FFFFFF); // rgba(255,255,255,0.6)
  /// Cam efekti kenarlık rengi (80% opaklık beyaz)
  static const Color glassBorder = Color(0xCCFFFFFF); // rgba(255,255,255,0.8)
  /// Arka plan gradient başlangıç (mint yeşili)
  static const Color bgGradientStart = Color(0xFFF0FDF4); // bg-gradient-start
  /// Arka plan gradient bitiş (açık mavi)
  static const Color bgGradientEnd = Color(0xFFEFF6FF); // bg-gradient-end
  /// Cam paneli gölge rengi (teal tinted)
  static const Color glassShadow = Color(0x1414B8A6); // rgba(20,184,166,0.08)

  // ────────────────────────────────────────────
  // Sosyal / Etkileşim
  // ────────────────────────────────────────────
  static const Color like = Color(0xFFEF4444); // status-error
  static const Color bookmark = Color(0xFFF59E0B); // Amber
  static const Color comment = Color(0xFF085AC0); // secondary blue
  static const Color share = Color(0xFF8B5CF6); // Violet
  static const Color bestAnswer = Color(0xFF22C55E); // Green

  // ────────────────────────────────────────────
  // Rozet Renkleri
  // ────────────────────────────────────────────
  static const Color badgeBronze = Color(0xFFCD7F32);
  static const Color badgeSilver = Color(0xFFC0C0C0);
  static const Color badgeGold = Color(0xFFFFD700);

  // ────────────────────────────────────────────
  // Shimmer (Loading placeholder)
  // ────────────────────────────────────────────
  static const Color shimmerBaseLight = Color(0xFFE0E3E1); // surface-variant
  static const Color shimmerHighlightLight = Color(
    0xFFF1F4F2,
  ); // surface-container-low
  static const Color shimmerBaseDark = Color(0xFF3E4946); // on-surface-variant
  static const Color shimmerHighlightDark = Color(0xFF6E7976); // outline
}
