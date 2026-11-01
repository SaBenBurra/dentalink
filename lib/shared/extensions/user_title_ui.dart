import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/enums.dart';
import 'dental_branch_ui.dart';

/// UserTitle enum'u için UI katmanı extension'ları.
///
/// Data katmanındaki enum'dan Flutter/Material bağımlılığını ayırır (SRP).
extension UserTitleUI on UserTitle {
  /// Aktif dilde unvan adı.
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
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
    };
  }

  /// Unvanın SVG ikonu; uzmanlar kendi branşının ikonunu kullanır.
  String get iconAsset => switch (this) {
    UserTitle.ogrenci => dentalIconAsset('student'),
    UserTitle.disHekimi => dentalIconAsset('general_dentistry'),
    UserTitle.endodontist => DentalBranch.endodonti.iconAsset,
    UserTitle.ortodontist => DentalBranch.ortodonti.iconAsset,
    UserTitle.periodontolog => DentalBranch.periodontoloji.iconAsset,
    UserTitle.protezUzmani => DentalBranch.protetikDisTedavisi.iconAsset,
    UserTitle.pedodontist => DentalBranch.pedodonti.iconAsset,
    UserTitle.agizDisCeneCerrahisi =>
      DentalBranch.agizDisCeneCerrahisi.iconAsset,
    UserTitle.agizDisCeneRadyoloji =>
      DentalBranch.agizDisCeneRadyolojisi.iconAsset,
    UserTitle.restoratifDisTedavisi =>
      DentalBranch.restoratifDisTedavisi.iconAsset,
  };
}
