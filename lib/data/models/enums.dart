/// DentLink — Tüm domain enum tanımları.
/// Faz 3'te Supabase'in PostgreSQL enum'larıyla eşleştirilir.
library;

import 'package:flutter/material.dart';

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
  restoratifDisTedavisi;

  String get displayName {
    switch (this) {
      case UserTitle.ogrenci:
        return 'Öğrenci';
      case UserTitle.disHekimiGenelPratisyen:
        return 'Genel Diş Hekimi';
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
      case UserTitle.restoratifDisTedavisi:
        return 'Restoratif Diş Tedavisi Uzmanı';
    }
  }

  IconData get titleIcon {
    switch (this) {
      case UserTitle.ogrenci:
        return Icons.school_outlined;
      case UserTitle.disHekimiGenelPratisyen:
        return Icons.medical_services_outlined;
      case UserTitle.endodontist:
        return Icons.biotech_outlined;
      case UserTitle.ortodontist:
        return Icons.align_horizontal_center_outlined;
      case UserTitle.periodontolog:
        return Icons.layers_outlined;
      case UserTitle.protezUzmani:
        return Icons.grid_view_outlined;
      case UserTitle.pedodontist:
        return Icons.child_care_outlined;
      case UserTitle.agizDisCeneCerrahisi:
        return Icons.healing_outlined;
      case UserTitle.agizDisCeneRadyoloji:
        return Icons.settings_system_daydream_outlined;
      case UserTitle.restoratifDisTedavisi:
        return Icons.auto_awesome_outlined;
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
