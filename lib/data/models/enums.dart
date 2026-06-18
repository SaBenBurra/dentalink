/// DentLink — Tüm domain enum tanımları.
/// Faz 3'te Supabase'in PostgreSQL enum'larıyla eşleştirilir.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Kullanıcı Unvanları
// ─────────────────────────────────────────────────────────────────────────────

enum UserTitle {
  ogrenci,
  disHekimiGenelPratisyen,
  endodontist,
  ortodontist,
  periodontolog,
  protezUzmani,
  pedodontist,
  agizDisCeneCerrahisi,
  agizDisCeneRadyoloji,
  oralDiagnoz,
  restoratifDisTedavisi;

  String get displayName {
    switch (this) {
      case UserTitle.ogrenci:
        return 'Öğrenci';
      case UserTitle.disHekimiGenelPratisyen:
        return 'Diş Hekimi (Genel Pratisyen)';
      case UserTitle.endodontist:
        return 'Endodontist';
      case UserTitle.ortodontist:
        return 'Ortodontist';
      case UserTitle.periodontolog:
        return 'Periodontolog';
      case UserTitle.protezUzmani:
        return 'Protez Uzmanı';
      case UserTitle.pedodontist:
        return 'Pedodontist';
      case UserTitle.agizDisCeneCerrahisi:
        return 'Ağız, Diş ve Çene Cerrahı';
      case UserTitle.agizDisCeneRadyoloji:
        return 'Ağız, Diş ve Çene Radyoloğu';
      case UserTitle.oralDiagnoz:
        return 'Oral Diagnoz Uzmanı';
      case UserTitle.restoratifDisTedavisi:
        return 'Restoratif Diş Tedavisi Uzmanı';
    }
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

  String get displayName {
    switch (this) {
      case DentalBranch.pedodonti:
        return 'Pedodonti';
      case DentalBranch.endodonti:
        return 'Endodonti';
      case DentalBranch.ortodonti:
        return 'Ortodonti';
      case DentalBranch.periodontoloji:
        return 'Periodontoloji';
      case DentalBranch.protetikDisTedavisi:
        return 'Protetik Diş Tedavisi';
      case DentalBranch.agizDisCeneCerrahisi:
        return 'Ağız, Diş ve Çene Cerrahisi';
      case DentalBranch.agizDisCeneRadyolojisi:
        return 'Ağız, Diş ve Çene Radyolojisi';
      case DentalBranch.oralDiagnoz:
        return 'Oral Diagnoz';
      case DentalBranch.restoratifDisTedavisi:
        return 'Restoratif Diş Tedavisi';
    }
  }

  /// Supabase'deki PostgreSQL ENUM değeriyle eşleşir.
  String get dbValue {
    switch (this) {
      case DentalBranch.pedodonti:
        return 'pedodonti';
      case DentalBranch.endodonti:
        return 'endodonti';
      case DentalBranch.ortodonti:
        return 'ortodonti';
      case DentalBranch.periodontoloji:
        return 'periodontoloji';
      case DentalBranch.protetikDisTedavisi:
        return 'protetik_dis_tedavisi';
      case DentalBranch.agizDisCeneCerrahisi:
        return 'agiz_dis_cene_cerrahisi';
      case DentalBranch.agizDisCeneRadyolojisi:
        return 'agiz_dis_cene_radyolojisi';
      case DentalBranch.oralDiagnoz:
        return 'oral_diagnoz';
      case DentalBranch.restoratifDisTedavisi:
        return 'restoratif_dis_tedavisi';
    }
  }

  static DentalBranch fromDbValue(String value) {
    return DentalBranch.values.firstWhere((e) => e.dbValue == value);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gönderi Türleri
// ─────────────────────────────────────────────────────────────────────────────

enum PostType {
  casePost,
  question;

  String get dbValue => this == PostType.casePost ? 'case' : 'question';

  static PostType fromDbValue(String value) =>
      value == 'case' ? PostType.casePost : PostType.question;
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

  String get dbValue {
    switch (this) {
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.message:
        return 'message';
      case NotificationType.bestAnswer:
        return 'best_answer';
      case NotificationType.badge:
        return 'badge';
    }
  }

  static NotificationType fromDbValue(String value) {
    return NotificationType.values.firstWhere((e) => e.dbValue == value);
  }
}
