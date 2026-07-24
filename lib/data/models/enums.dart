/// DentLink — Tüm domain enum tanımları.
/// Faz 3'te Supabase'in PostgreSQL enum'larıyla eşleştirilir.
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kullanıcı Unvanları
// ─────────────────────────────────────────────────────────────────────────────

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

  String get displayName {
    switch (this) {
      case UserTitle.ogrenci:
        return 'Öğrenci';
      case UserTitle.disHekimi:
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
      case UserTitle.oralDiagnoz:
        return 'Oral Diagnoz Uzmanı';
    }
  }

  IconData get titleIcon {
    switch (this) {
      case UserTitle.ogrenci:
        return Icons.school_outlined;
      case UserTitle.disHekimi:
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
      case UserTitle.oralDiagnoz:
        return Icons.medical_information_outlined;
      case UserTitle.restoratifDisTedavisi:
        return Icons.auto_awesome_outlined;
    }
  }

  String get dbValue {
    switch (this) {
      case UserTitle.ogrenci:
        return 'ogrenci';
      case UserTitle.disHekimi:
        return 'dis_hekimi_genel_pratisyen';
      case UserTitle.endodontist:
        return 'endodontist';
      case UserTitle.ortodontist:
        return 'ortodontist';
      case UserTitle.periodontolog:
        return 'periodontolog';
      case UserTitle.protezUzmani:
        return 'protez_uzmani';
      case UserTitle.pedodontist:
        return 'pedodontist';
      case UserTitle.agizDisCeneCerrahisi:
        return 'agiz_dis_cene_cerrahi';
      case UserTitle.agizDisCeneRadyoloji:
        return 'agiz_dis_cene_radyologu';
      case UserTitle.restoratifDisTedavisi:
        return 'restoratif_dis_tedavisi_uzmani';
      case UserTitle.oralDiagnoz:
        return 'oral_diagnoz_uzmani';
    }
  }

  static UserTitle fromDbValue(String? value) {
    if (value == null) return UserTitle.disHekimi;
    try {
      return UserTitle.values.firstWhere((e) => e.dbValue == value);
    } catch (_) {
      return UserTitle.disHekimi;
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
        return 'pedodontist';
      case DentalBranch.endodonti:
        return 'endodontist';
      case DentalBranch.ortodonti:
        return 'ortodontist';
      case DentalBranch.periodontoloji:
        return 'periodontolog';
      case DentalBranch.protetikDisTedavisi:
        return 'protez_uzmani';
      case DentalBranch.agizDisCeneCerrahisi:
        return 'agiz_dis_cene_cerrahi';
      case DentalBranch.agizDisCeneRadyolojisi:
        return 'agiz_dis_cene_radyologu';
      case DentalBranch.oralDiagnoz:
        return 'oral_diagnoz_uzmani';
      case DentalBranch.restoratifDisTedavisi:
        return 'restoratif_dis_tedavisi_uzmani';
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

  String get dbValue {
    return switch (this) {
      PostType.casePost => "case",
      PostType.question => "question",
    };
  }

  String get emoji {
    return switch (this) {
      PostType.casePost => '📸',
      PostType.question => '❓',
    };
  }

  static PostType fromDbValue(String value) {
    return switch (value) {
      'case' => PostType.casePost,
      'question' => PostType.question,
      String() => throw UnimplementedError(),
    };
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
