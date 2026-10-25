import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/enums.dart';

/// UserTitle enum'u için UI katmanı extension'ları.
///
/// Data katmanındaki enum'dan Flutter/Material bağımlılığını ayırır (SRP).
extension UserTitleUI on UserTitle {
  /// Aktif dilde unvan adı.
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      UserTitle.unknown => l10n.titleUnknown,
      UserTitle.ogrenci => l10n.titleStudent,
      UserTitle.disHekimi => l10n.titleGeneralDentist,
      UserTitle.endodontist => l10n.titleEndodontist,
      UserTitle.ortodontist => l10n.titleOrthodontist,
      UserTitle.periodontolog => l10n.titlePeriodontologist,
      UserTitle.protezUzmani => l10n.titleProsthodontist,
      UserTitle.pedodontist => l10n.titlePedodontist,
      UserTitle.agizDisCeneCerrahisi => l10n.titleOralSurgeon,
      UserTitle.agizDisCeneRadyoloji => l10n.titleOralRadiologist,
      UserTitle.restoratifDisTedavisi => l10n.titleRestorativeDentistry,
      UserTitle.oralDiagnoz => l10n.titleOralDiagnostics,
    };
  }

  /// Her unvan için özel Material ikonu.
  IconData get titleIcon => switch (this) {
    UserTitle.unknown => Icons.person_outline,
    UserTitle.ogrenci => Icons.school_outlined,
    UserTitle.disHekimi => Icons.medical_services_outlined,
    UserTitle.endodontist => Icons.biotech_outlined,
    UserTitle.ortodontist => Icons.align_horizontal_center_outlined,
    UserTitle.periodontolog => Icons.layers_outlined,
    UserTitle.protezUzmani => Icons.grid_view_outlined,
    UserTitle.pedodontist => Icons.child_care_outlined,
    UserTitle.agizDisCeneCerrahisi => Icons.healing_outlined,
    UserTitle.agizDisCeneRadyoloji => Icons.settings_system_daydream_outlined,
    UserTitle.oralDiagnoz => Icons.medical_information_outlined,
    UserTitle.restoratifDisTedavisi => Icons.auto_awesome_outlined,
  };
}
