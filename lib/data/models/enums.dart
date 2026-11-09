/// Dentigo — Tüm domain enum tanımları.
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
  restoratifDisTedavisi;

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
  };

  static UserTitle fromDbValue(String? value) {
    if (value == null) return UserTitle.disHekimi; // DB varsayılanı
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
  restoratifDisTedavisi;

  /// Supabase'deki PostgreSQL ENUM değeriyle eşleşir.
  String get dbValue => switch (this) {
    DentalBranch.pedodonti => 'pedodontist',
    DentalBranch.endodonti => 'endodontist',
    DentalBranch.ortodonti => 'ortodontist',
    DentalBranch.periodontoloji => 'periodontolog',
    DentalBranch.protetikDisTedavisi => 'protez_uzmani',
    DentalBranch.agizDisCeneCerrahisi => 'agiz_dis_cene_cerrahi',
    DentalBranch.agizDisCeneRadyolojisi => 'agiz_dis_cene_radyologu',
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
// Tedavi Türleri (migration 033)
// ─────────────────────────────────────────────────────────────────────────────

/// Vakanın tedavi türü. Her tür bir branşa ve bir tanımlı etikete bağlı;
/// etiket sunucuda posta zorunlu eklenir. Liste `treatment_types` tablosuyla
/// aynı olmalı (test/data/models/treatment_type_test.dart).
enum TreatmentType {
  // endodonti
  kanalTedavisi('kanal-tedavisi', 'kanal-tedavisi', DentalBranch.endodonti),
  yenidenKanalTedavisi(
    'yeniden-kanal-tedavisi',
    'yeniden-kanal-tedavisi',
    DentalBranch.endodonti,
  ),
  vitalPulpaTedavisi(
    'vital-pulpa-tedavisi',
    'vital-pulpa-tedavisi',
    DentalBranch.endodonti,
  ),
  apeksifikasyon('apeksifikasyon', 'apeksifikasyon', DentalBranch.endodonti),
  rejeneratifEndodonti(
    'rejeneratif-endodonti',
    'rejeneratif-endodonti',
    DentalBranch.endodonti,
  ),
  endodontikCerrahi(
    'endodontik-cerrahi',
    'endodontik-cerrahi',
    DentalBranch.endodonti,
  ),
  // restoratifDisTedavisi
  kompozit('kompozit', 'kompozit', DentalBranch.restoratifDisTedavisi),
  indirektRestorasyon(
    'indirekt-restorasyon',
    'indirekt-restorasyon',
    DentalBranch.restoratifDisTedavisi,
  ),
  kompozitVeneer(
    'kompozit-veneer',
    'kompozit-veneer',
    DentalBranch.restoratifDisTedavisi,
  ),
  beyazlatma('beyazlatma', 'beyazlatma', DentalBranch.restoratifDisTedavisi),
  diastema('diastema', 'diastema', DentalBranch.restoratifDisTedavisi),
  gulusTasarimi(
    'gulus-tasarimi',
    'gülüş-tasarımı',
    DentalBranch.restoratifDisTedavisi,
  ),
  // protetikDisTedavisi
  kron('kron', 'kron', DentalBranch.protetikDisTedavisi),
  kopru('kopru', 'köprü', DentalBranch.protetikDisTedavisi),
  lamineVeneer(
    'lamine-veneer',
    'lamine-veneer',
    DentalBranch.protetikDisTedavisi,
  ),
  totalProtez('total-protez', 'total-protez', DentalBranch.protetikDisTedavisi),
  parsiyelProtez(
    'parsiyel-protez',
    'parsiyel-protez',
    DentalBranch.protetikDisTedavisi,
  ),
  implantUstuProtez(
    'implant-ustu-protez',
    'implant-üstü-protez',
    DentalBranch.protetikDisTedavisi,
  ),
  tamAgizRehabilitasyonu(
    'tam-agiz-rehabilitasyonu',
    'tam-ağız-rehabilitasyonu',
    DentalBranch.protetikDisTedavisi,
  ),
  gecePlagi('gece-plagi', 'gece-plağı', DentalBranch.protetikDisTedavisi),
  // agizDisCeneCerrahisi
  disCekimi('dis-cekimi', 'diş-çekimi', DentalBranch.agizDisCeneCerrahisi),
  gomuluDis('gomulu-dis', 'gömülü-diş', DentalBranch.agizDisCeneCerrahisi),
  implant('implant', 'implant', DentalBranch.agizDisCeneCerrahisi),
  sinusLifting(
    'sinus-lifting',
    'sinüs-lifting',
    DentalBranch.agizDisCeneCerrahisi,
  ),
  kemikGrefti(
    'kemik-grefti',
    'kemik-grefti',
    DentalBranch.agizDisCeneCerrahisi,
  ),
  kist('kist', 'kist', DentalBranch.agizDisCeneCerrahisi),
  apikalRezeksiyon(
    'apikal-rezeksiyon',
    'apikal-rezeksiyon',
    DentalBranch.agizDisCeneCerrahisi,
  ),
  ortognatikCerrahi(
    'ortognatik-cerrahi',
    'ortognatik-cerrahi',
    DentalBranch.agizDisCeneCerrahisi,
  ),
  ceneKirigi('cene-kirigi', 'çene-kırığı', DentalBranch.agizDisCeneCerrahisi),
  // periodontoloji
  disTasi('dis-tasi', 'diş-taşı', DentalBranch.periodontoloji),
  kokYuzeyiDuzlestirme(
    'kok-yuzeyi-duzlestirme',
    'kök-yüzeyi-düzleştirme',
    DentalBranch.periodontoloji,
  ),
  flepOperasyonu(
    'flep-operasyonu',
    'flep-operasyonu',
    DentalBranch.periodontoloji,
  ),
  rejeneratifPeriodontalTedavi(
    'rejeneratif-periodontal-tedavi',
    'rejeneratif-periodontal-tedavi',
    DentalBranch.periodontoloji,
  ),
  bagDokusuGrefti(
    'bag-dokusu-grefti',
    'bağ-dokusu-grefti',
    DentalBranch.periodontoloji,
  ),
  serbestDisetiGrefti(
    'serbest-diseti-grefti',
    'serbest-dişeti-grefti',
    DentalBranch.periodontoloji,
  ),
  kronBoyuUzatma(
    'kron-boyu-uzatma',
    'kron-boyu-uzatma',
    DentalBranch.periodontoloji,
  ),
  gingivektomi('gingivektomi', 'gingivektomi', DentalBranch.periodontoloji),
  periImplantitis(
    'peri-implantitis',
    'peri-implantitis',
    DentalBranch.periodontoloji,
  ),
  // ortodonti
  braket('braket', 'braket', DentalBranch.ortodonti),
  seffafPlak('seffaf-plak', 'şeffaf-plak', DentalBranch.ortodonti),
  fonksiyonelAparey(
    'fonksiyonel-aparey',
    'fonksiyonel-aparey',
    DentalBranch.ortodonti,
  ),
  hizliUstCeneGenisletme(
    'hizli-ust-cene-genisletme',
    'hızlı-üst-çene-genişletme',
    DentalBranch.ortodonti,
  ),
  interseptifOrtodonti(
    'interseptif-ortodonti',
    'interseptif-ortodonti',
    DentalBranch.ortodonti,
  ),
  miniVida('mini-vida', 'mini-vida', DentalBranch.ortodonti),
  pekistirme('pekistirme', 'pekiştirme', DentalBranch.ortodonti),
  // pedodonti
  pulpotomi('pulpotomi', 'pulpotomi', DentalBranch.pedodonti),
  sutDisiKanalTedavisi(
    'sut-disi-kanal-tedavisi',
    'süt-dişi-kanal-tedavisi',
    DentalBranch.pedodonti,
  ),
  fissurOrtucu('fissur-ortucu', 'fissür-örtücü', DentalBranch.pedodonti),
  florUygulamasi('flor-uygulamasi', 'flor-uygulaması', DentalBranch.pedodonti),
  yerTutucu('yer-tutucu', 'yer-tutucu', DentalBranch.pedodonti),
  paslanmazCelikKuron(
    'paslanmaz-celik-kuron',
    'paslanmaz-çelik-kuron',
    DentalBranch.pedodonti,
  ),
  disTravmasi('dis-travmasi', 'diş-travması', DentalBranch.pedodonti),
  genelAnestezi('genel-anestezi', 'genel-anestezi', DentalBranch.pedodonti),
  // agizDisCeneRadyolojisi
  panoramik('panoramik', 'panoramik', DentalBranch.agizDisCeneRadyolojisi),
  periapikalRontgen(
    'periapikal-rontgen',
    'periapikal-röntgen',
    DentalBranch.agizDisCeneRadyolojisi,
  ),
  bitewing('bitewing', 'bitewing', DentalBranch.agizDisCeneRadyolojisi),
  cbct('cbct', 'cbct', DentalBranch.agizDisCeneRadyolojisi),
  sefalometrikRontgen(
    'sefalometrik-rontgen',
    'sefalometrik-röntgen',
    DentalBranch.agizDisCeneRadyolojisi,
  );

  /// `treatment_types.code` (etiketin slug'ı).
  final String dbValue;

  /// Posta sabitlenen etiketin adı.
  final String tag;
  final DentalBranch branch;

  const TreatmentType(this.dbValue, this.tag, this.branch);

  static List<TreatmentType> forBranch(DentalBranch branch) => [
    for (final t in values)
      if (t.branch == branch) t,
  ];

  static TreatmentType? tryFromDbValue(String? value) {
    for (final e in values) {
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
  question,

  /// Ticaret: 2. el malzeme ilanı (052). Konuşma DM'de, iki kişi arasında.
  listing;

  String get dbValue {
    return switch (this) {
      PostType.casePost => "case",
      PostType.question => "question",
      PostType.listing => "listing",
    };
  }

  /// Post sahibi bir yorumu "En İyi Cevap" seçebilir mi. Forumda (`question`)
  /// soru şartı olmadığından kapalı; özellik ileride başka bir tür için açılabilir.
  bool get allowsBestAnswer => switch (this) {
    PostType.casePost || PostType.question || PostType.listing => false,
  };

  /// Beğeni ve yorum. İlanda kapalı (052): pazarlık herkesin önünde olmasın.
  bool get allowsSocial => this != PostType.listing;

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
    PostType.listing,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticaret ilanı (posts.listing_category / item_condition CHECK'leri, 052)
// ─────────────────────────────────────────────────────────────────────────────

enum ListingCategory {
  handInstruments('hand_instruments'),
  rotary('rotary'),
  equipment('equipment'),
  consumables('consumables'),
  books('books'),
  models('models'),
  other('other');

  final String dbValue;
  const ListingCategory(this.dbValue);

  static ListingCategory fromDbValue(String? value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => other);
}

enum ItemCondition {
  brandNew('new'),
  likeNew('like_new'),
  used('used');

  final String dbValue;
  const ItemCondition(this.dbValue);

  static ItemCondition fromDbValue(String? value) =>
      values.firstWhere((e) => e.dbValue == value, orElse: () => used);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gönderi Menü Aksiyonları
// ─────────────────────────────────────────────────────────────────────────────

enum PostMenuAction { edit, delete, report, block }

// ─────────────────────────────────────────────────────────────────────────────
// Raporlama (reports tablosu CHECK değerleriyle eşleşir, migration 023)
// ─────────────────────────────────────────────────────────────────────────────

enum ReportTarget {
  post,
  comment,
  user;

  String get dbValue => name;
}

enum ReportReason {
  spam,
  harassment,
  patientPrivacy,
  misinformation,
  inappropriate,
  prohibitedItem,
  other;

  String get dbValue => switch (this) {
    ReportReason.patientPrivacy => 'patient_privacy',
    ReportReason.prohibitedItem => 'prohibited_item',
    _ => name,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Bildirim Türleri (notification_type PostgreSQL ENUM ile eşleşir)
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationType {
  like,
  comment,
  reply,
  follow,
  message,
  bestAnswer,
  badge;

  String get dbValue => switch (this) {
    NotificationType.like => 'like',
    NotificationType.comment => 'comment',
    NotificationType.reply => 'reply',
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
