import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/enums.dart';

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
      DentalBranch.oralDiagnoz => l10n.branchOralDiagnosis,
      DentalBranch.restoratifDisTedavisi => l10n.branchRestorativeDentistry,
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
    DentalBranch.agizDisCeneRadyolojisi => AppColors.branchAgizDisCeneRadyolojisi,
    DentalBranch.oralDiagnoz => AppColors.branchOralDiagnoz,
    DentalBranch.restoratifDisTedavisi => AppColors.branchRestoratifDisTedavisi,
  };
}
