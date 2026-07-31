import 'package:flutter/material.dart';
import '../../data/models/enums.dart';

/// UserTitle enum'u için UI katmanı extension'ları.
///
/// Data katmanındaki enum'dan Flutter/Material bağımlılığını ayırır (SRP).
extension UserTitleUI on UserTitle {
  /// Her unvan için özel Material ikonu.
  IconData get titleIcon => switch (this) {
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
