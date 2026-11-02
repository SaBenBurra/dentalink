import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/enums.dart';

/// `assets/dental-icons/` altındaki SVG ikonun yolu.
String dentalIconAsset(String name) => 'assets/dental-icons/$name.svg';

/// DentalBranch enum'u için UI katmanı extension'ları.
///
/// Branş renk eşleştirmesini presentation katmanında tutar (SRP/OCP).
extension DentalBranchUI on DentalBranch {
  /// Aktif dilde branş adı.
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      DentalBranch.pedodonti => l10n.branchPedodontics,
      DentalBranch.endodonti => l10n.branchEndodontics,
      DentalBranch.ortodonti => l10n.branchOrthodontics,
      DentalBranch.periodontoloji => l10n.branchPeriodontology,
      DentalBranch.protetikDisTedavisi => l10n.branchProsthodontics,
      DentalBranch.agizDisCeneCerrahisi => l10n.branchOralSurgery,
      DentalBranch.agizDisCeneRadyolojisi => l10n.branchOralRadiology,
      DentalBranch.restoratifDisTedavisi => l10n.branchRestorativeDentistry,
    };
  }

  /// Dar yerler için hekimlerin kullandığı kısa ad (Endo, Perio…).
  String shortName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      DentalBranch.pedodonti => l10n.branchShortPedodontics,
      DentalBranch.endodonti => l10n.branchShortEndodontics,
      DentalBranch.ortodonti => l10n.branchShortOrthodontics,
      DentalBranch.periodontoloji => l10n.branchShortPeriodontology,
      DentalBranch.protetikDisTedavisi => l10n.branchShortProsthodontics,
      DentalBranch.agizDisCeneCerrahisi => l10n.branchShortOralSurgery,
      DentalBranch.agizDisCeneRadyolojisi => l10n.branchShortOralRadiology,
      DentalBranch.restoratifDisTedavisi =>
        l10n.branchShortRestorativeDentistry,
    };
  }

  /// Branş rengi; koyu temada açık tonu (ikisi de zemine karşı ≥ 4.5:1).
  Color colorOf(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      DentalBranch.endodonti =>
        dark ? AppColors.branchEndodontiDark : AppColors.branchEndodonti,
      DentalBranch.restoratifDisTedavisi =>
        dark ? AppColors.branchRestoratifDark : AppColors.branchRestoratif,
      DentalBranch.protetikDisTedavisi =>
        dark ? AppColors.branchProtetikDark : AppColors.branchProtetik,
      DentalBranch.agizDisCeneCerrahisi =>
        dark ? AppColors.branchCerrahiDark : AppColors.branchCerrahi,
      DentalBranch.periodontoloji =>
        dark
            ? AppColors.branchPeriodontolojiDark
            : AppColors.branchPeriodontoloji,
      DentalBranch.ortodonti =>
        dark ? AppColors.branchOrtodontiDark : AppColors.branchOrtodonti,
      DentalBranch.pedodonti =>
        dark ? AppColors.branchPedodontiDark : AppColors.branchPedodonti,
      DentalBranch.agizDisCeneRadyolojisi =>
        dark ? AppColors.branchRadyolojiDark : AppColors.branchRadyoloji,
    };
  }

  /// Branşın SVG ikonu (`DentalIcon` ile çizilir).
  String get iconAsset => dentalIconAsset(switch (this) {
    DentalBranch.pedodonti => 'pediatric_dentistry',
    DentalBranch.endodonti => 'endodontics',
    DentalBranch.ortodonti => 'orthodontics',
    DentalBranch.periodontoloji => 'periodontics',
    DentalBranch.protetikDisTedavisi => 'prosthodontics',
    DentalBranch.agizDisCeneCerrahisi => 'surgery',
    DentalBranch.agizDisCeneRadyolojisi => 'radiology',
    DentalBranch.restoratifDisTedavisi => 'restorative',
  });
}
