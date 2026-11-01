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

  /// Her branşa özgü tema rengi.
  Color get color => switch (this) {
    DentalBranch.pedodonti => AppColors.branchPedodonti,
    DentalBranch.endodonti => AppColors.branchEndodonti,
    DentalBranch.ortodonti => AppColors.branchOrtodonti,
    DentalBranch.periodontoloji => AppColors.branchPeriodontoloji,
    DentalBranch.protetikDisTedavisi => AppColors.branchProtetikDisTedavisi,
    DentalBranch.agizDisCeneCerrahisi => AppColors.branchAgizDisCeneCerrahisi,
    DentalBranch.agizDisCeneRadyolojisi =>
      AppColors.branchAgizDisCeneRadyolojisi,
    DentalBranch.restoratifDisTedavisi => AppColors.branchRestoratifDisTedavisi,
  };

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
