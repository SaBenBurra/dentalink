/// DentLink — Tüm domain enum tanımları.
/// Faz 3'te Supabase'in PostgreSQL enum'larıyla eşleştirilir.
library;
enum UserTitle {
  ogrenci,
  disHekimi,
  endodontist,
  ortodontist,
  periodontolog,
  protezUzmani,
  pedodontist,
  agizDisCeneCerrahisi,
  agizDisCeneRadyoloji,
  restoratifDisTedavisi,
  oralDiagnoz;

  String get displayName => switch (this) {
    UserTitle.ogrenci => 'Öğrenci',
    UserTitle.disHekimi => 'Genel Diş Hekimi',
    UserTitle.endodontist => 'Endodontist',
    UserTitle.ortodontist => 'Ortodontist',
    UserTitle.periodontolog => 'Periodontolog',
    UserTitle.protezUzmani => 'Protez Uzmanı',
    UserTitle.pedodontist => 'Pedodontist',
    UserTitle.agizDisCeneCerrahisi => 'Ağız, Diş ve Çene Cerrahı',
    UserTitle.agizDisCeneRadyoloji => 'Ağız, Diş ve Çene Radyoloğu',
    UserTitle.restoratifDisTedavisi => 'Restoratif Diş Tedavisi Uzmanı',
    UserTitle.oralDiagnoz => 'Oral Diagnoz Uzmanı',
  };

  String get dbValue => switch (this) {
    UserTitle.ogrenci => 'ogrenci',
    UserTitle.disHekimi => 'dis_hekimi',
    UserTitle.endodontist => 'endodontist',
    UserTitle.ortodontist => 'ortodontist',
    UserTitle.periodontolog => 'periodontolog',
    UserTitle.protezUzmani => 'protez_uzmani',
    UserTitle.pedodontist => 'pedodontist',
    UserTitle.agizDisCeneCerrahisi => 'agiz_dis_cene_cerrahi',
    UserTitle.agizDisCeneRadyoloji => 'agiz_dis_cene_radyologu',
    UserTitle.restoratifDisTedavisi => 'restoratif_dis_tedavisi_uzmani',
    UserTitle.oralDiagnoz => 'oral_diagnoz_uzmani',
  };

  static UserTitle fromDbValue(String? value) {
    if (value == null) return UserTitle.disHekimi;
    for (final e in UserTitle.values) {
      if (e.dbValue == value) return e;
    }
    throw ArgumentError('Unknown UserTitle dbValue: $value');
  }

  static UserTitle? tryFromDbValue(String? value) {
    if (value == null) return null;
    for (final e in UserTitle.values) {
      if (e.dbValue == value) return e;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diş Hekimliği Branşları (dental_branch PostgreSQL ENUM ile eşleşir)
// ─────────────────────────────────────────────────────────────────────────────

enum DentalBranch {
  pedodonti,
  endodonti,
  ortodonti,
  periodontoloji,
  protetikDisTedavisi,
  agizDisCeneCerrahisi,
  agizDisCeneRadyolojisi,
  oralDiagnoz,
  restoratifDisTedavisi;

  String get displayName => switch (this) {
    DentalBranch.pedodonti => 'Pedodonti',
    DentalBranch.endodonti => 'Endodonti',
    DentalBranch.ortodonti => 'Ortodonti',
    DentalBranch.periodontoloji => 'Periodontoloji',
    DentalBranch.protetikDisTedavisi => 'Protetik Diş Tedavisi',
    DentalBranch.agizDisCeneCerrahisi => 'Ağız, Diş ve Çene Cerrahisi',
    DentalBranch.agizDisCeneRadyolojisi => 'Ağız, Diş ve Çene Radyolojisi',
    DentalBranch.oralDiagnoz => 'Oral Diagnoz',
    DentalBranch.restoratifDisTedavisi => 'Restoratif Diş Tedavisi',
  };

  /// Supabase'deki PostgreSQL ENUM değeriyle eşleşir.
  String get dbValue => switch (this) {
    DentalBranch.pedodonti => 'pedodontist',
    DentalBranch.endodonti => 'endodontist',
    DentalBranch.ortodonti => 'ortodontist',
    DentalBranch.periodontoloji => 'periodontolog',
    DentalBranch.protetikDisTedavisi => 'protez_uzmani',
    DentalBranch.agizDisCeneCerrahisi => 'agiz_dis_cene_cerrahi',
    DentalBranch.agizDisCeneRadyolojisi => 'agiz_dis_cene_radyologu',
    DentalBranch.oralDiagnoz => 'oral_diagnoz_uzmani',
    DentalBranch.restoratifDisTedavisi => 'restoratif_dis_tedavisi_uzmani',
  };

  static DentalBranch fromDbValue(String value) {
    for (final e in DentalBranch.values) {
      if (e.dbValue == value) return e;
    }
    throw ArgumentError('Unknown DentalBranch dbValue: $value');
  }

  static DentalBranch? tryFromDbValue(String? value) {
    if (value == null) return null;
    for (final e in DentalBranch.values) {
      if (e.dbValue == value) return e;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gönderi Türleri
// ─────────────────────────────────────────────────────────────────────────────

enum PostType {
  casePost,
  question;

  String get dbValue {
    return switch (this) {
      PostType.casePost => "case",
      PostType.question => "question",
    };
  }

  static PostType fromDbValue(String value) {
    for (final e in PostType.values) {
      if (e.dbValue == value) return e;
    }
    throw ArgumentError('Unknown PostType dbValue: $value');
  }

  static PostType? tryFromDbValue(String? value) {
    if (value == null) return null;
    for (final e in PostType.values) {
      if (e.dbValue == value) return e;
    }
    return null;
  }

  static const List<PostType> profileTabs = [
    PostType.casePost,
    PostType.question,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Bildirim Türleri (notification_type PostgreSQL ENUM ile eşleşir)
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationType {
  like,
  comment,
  follow,
  message,
  bestAnswer,
  badge;

  String get dbValue => switch (this) {
    NotificationType.like => 'like',
    NotificationType.comment => 'comment',
    NotificationType.follow => 'follow',
    NotificationType.message => 'message',
    NotificationType.bestAnswer => 'best_answer',
    NotificationType.badge => 'badge',
  };

  static NotificationType fromDbValue(String value) {
    for (final e in NotificationType.values) {
      if (e.dbValue == value) return e;
    }
    throw ArgumentError('Unknown NotificationType dbValue: $value');
  }

  static NotificationType? tryFromDbValue(String? value) {
    if (value == null) return null;
    for (final e in NotificationType.values) {
      if (e.dbValue == value) return e;
    }
    return null;
  }
}
