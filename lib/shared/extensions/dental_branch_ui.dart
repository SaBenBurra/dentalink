import 'package:flutter/material.dart';
import '../../data/models/enums.dart';

/// DentalBranch enum'u için UI katmanı extension'ları.
///
/// Branş renk eşleştirmesini presentation katmanında tutar (SRP/OCP).
extension DentalBranchUI on DentalBranch {
  /// Her branşa özgü tema rengi.
  Color get color => switch (this) {
    DentalBranch.pedodonti => const Color(0xFFE91E63),
    DentalBranch.endodonti => const Color(0xFF2196F3),
    DentalBranch.ortodonti => const Color(0xFF9C27B0),
    DentalBranch.periodontoloji => const Color(0xFF4CAF50),
    DentalBranch.protetikDisTedavisi => const Color(0xFFFF9800),
    DentalBranch.agizDisCeneCerrahisi => const Color(0xFFF44336),
    DentalBranch.agizDisCeneRadyolojisi => const Color(0xFF00BCD4),
    DentalBranch.oralDiagnoz => const Color(0xFF795548),
    DentalBranch.restoratifDisTedavisi => const Color(0xFF607D8B),
  };
}
