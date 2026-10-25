import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/enums.dart';

/// DentalBranch enum'u için UI katmanı extension'ları.
///
/// Branş renk eşleştirmesini presentation katmanında tutar (SRP/OCP).
extension DentalBranchUI on DentalBranch {
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
