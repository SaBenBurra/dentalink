import '../models/badge_model.dart';
import '../models/comment_model.dart';
import '../models/conversation_model.dart';
import '../models/enums.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../models/tag_model.dart';
import '../models/user_model.dart';

/// Tüm mock verinin tek kaynağı.
/// Faz 3'te bu dosya Supabase datasource ile tamamen değiştirilir.
/// Provider'lar ve repository'ler bu sınıftan bağımsızdır.
class MockDatasource {
  MockDatasource._();

  static final MockDatasource instance = MockDatasource._();

  // ─── Mevcut oturum açmış kullanıcı ───────────────────────────────────────

  /// Mock oturumda ilk kullanıcı oturum açmış kabul edilir.
  static const String currentUserId = 'u1';

  // ─── Yardımcı zaman üreticileri ──────────────────────────────────────────

  static DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) {
    return DateTime.now().subtract(
      Duration(days: days, hours: hours, minutes: minutes),
    );
  }

  // ─── Etiketler ───────────────────────────────────────────────────────────

  static final List<TagModel> tags = [
    const TagModel(
      id: 't1',
      name: 'Kanal Tedavisi',
      slug: 'kanal-tedavisi',
      usageCount: 48,
    ),
    const TagModel(
      id: 't2',
      name: 'Kompozit',
      slug: 'kompozit',
      usageCount: 37,
    ),
    const TagModel(id: 't3', name: 'Implant', slug: 'implant', usageCount: 65),
    const TagModel(
      id: 't4',
      name: 'Zirkonyum',
      slug: 'zirkonyum',
      usageCount: 29,
    ),
    const TagModel(id: 't5', name: 'Veneer', slug: 'veneer', usageCount: 22),
    const TagModel(
      id: 't6',
      name: 'Ortodontik Tedavi',
      slug: 'ortodontik-tedavi',
      usageCount: 41,
    ),
    const TagModel(
      id: 't7',
      name: 'Periodontal Tedavi',
      slug: 'periodontal-tedavi',
      usageCount: 19,
    ),
    const TagModel(
      id: 't8',
      name: 'Gömülü Diş',
      slug: 'gomulu-dis',
      usageCount: 33,
    ),
    const TagModel(
      id: 't9',
      name: 'Süt Dişi',
      slug: 'sut-disi',
      usageCount: 15,
    ),
    const TagModel(
      id: 't10',
      name: 'Diş Beyazlatma',
      slug: 'dis-beyazlatma',
      usageCount: 28,
    ),
    const TagModel(id: 't11', name: 'Apse', slug: 'apse', usageCount: 11),
    const TagModel(
      id: 't12',
      name: 'Porselen',
      slug: 'porselen',
      usageCount: 24,
    ),
  ];

  // ─── Kullanıcılar ─────────────────────────────────────────────────────────

  static final List<UserModel> users = [
    UserModel(
      id: 'u1',
      email: 'ahmet.yilmaz@dentlink.com',
      fullName: 'Dr. Ahmet Yılmaz',
      username: 'ahmet_yilmaz',
      title: UserTitle.endodontist,
      bio:
          'Endodonti uzmanı. Karmaşık kanal tedavileri ve apikal cerrahide 8 yıllık deneyim.',
      university: 'Hacettepe Üniversitesi',
      city: 'İstanbul',
      experienceYears: 8,
      workplace: 'Acıbadem Fulya Hastanesi',
      followersCount: 342,
      followingCount: 87,
      postsCount: 24,
      isVerified: true,
      onboardingCompleted: true,
      lastSeenAt: _ago(minutes: 5),
      createdAt: _ago(days: 420),
    ),
    UserModel(
      id: 'u2',
      email: 'zeynep.kaya@dentlink.com',
      fullName: 'Dr. Zeynep Kaya',
      username: 'zeynep_kaya',
      title: UserTitle.ortodontist,
      bio:
          'Ortodonti uzmanı. İnvisalign ve lingual ortodonti konularında deneyimliyim.',
      university: 'Gazi Üniversitesi',
      city: 'Ankara',
      experienceYears: 5,
      workplace: 'Medicana Hastanesi',
      followersCount: 218,
      followingCount: 63,
      postsCount: 17,
      onboardingCompleted: true,
      lastSeenAt: _ago(hours: 2),
      createdAt: _ago(days: 310),
    ),
    UserModel(
      id: 'u3',
      email: 'mehmet.demir@dentlink.com',
      fullName: 'Dr. Mehmet Demir',
      username: 'mehmet_demir',
      title: UserTitle.protezUzmani,
      bio:
          'Protetik diş tedavisi uzmanı. Tam protez ve implant üstü protezlerde 12 yıllık tecrübe.',
      university: 'Ege Üniversitesi',
      city: 'İzmir',
      experienceYears: 12,
      workplace: 'EGE Oral Center',
      followersCount: 489,
      followingCount: 112,
      postsCount: 36,
      isVerified: true,
      onboardingCompleted: true,
      lastSeenAt: _ago(hours: 1),
      createdAt: _ago(days: 580),
    ),
    UserModel(
      id: 'u4',
      email: 'ayse.celik@dentlink.com',
      fullName: 'Dr. Ayşe Çelik',
      username: 'ayse_celik',
      title: UserTitle.pedodontist,
      bio:
          'Çocuk diş hekimliği uzmanı. Anksiyeteli çocuklarda davranış yönetimi üzerine çalışıyorum.',
      university: 'Uludağ Üniversitesi',
      city: 'Bursa',
      experienceYears: 3,
      workplace: 'Özel Çocuk Diş Kliniği',
      followersCount: 156,
      followingCount: 94,
      postsCount: 12,
      onboardingCompleted: true,
      lastSeenAt: _ago(hours: 6),
      createdAt: _ago(days: 200),
    ),
    UserModel(
      id: 'u5',
      email: 'can.arslan@dentlink.com',
      fullName: 'Dr. Can Arslan',
      username: 'can_arslan',
      title: UserTitle.periodontolog,
      bio:
          'Periodontoloji uzmanı. Lazer periodontal tedavi ve doku rejenerasyonunda deneyimliyim.',
      university: 'Marmara Üniversitesi',
      city: 'İstanbul',
      experienceYears: 7,
      workplace: 'İstanbul Oral & Dental Center',
      followersCount: 274,
      followingCount: 78,
      postsCount: 19,
      onboardingCompleted: true,
      lastSeenAt: _ago(minutes: 45),
      createdAt: _ago(days: 390),
    ),
    UserModel(
      id: 'u6',
      email: 'elif.sahin@dentlink.com',
      fullName: 'Dr. Elif Şahin',
      username: 'elif_sahin',
      title: UserTitle.restoratifDisTedavisi,
      bio:
          'Restoratif diş tedavisi uzmanı. Estetik diş hekimliği ve minimal invaziv yaklaşımlar.',
      university: 'Ankara Üniversitesi',
      city: 'Ankara',
      experienceYears: 4,
      workplace: 'Kızılay Ağız ve Diş Sağlığı Polikliniği',
      followersCount: 193,
      followingCount: 121,
      postsCount: 15,
      onboardingCompleted: true,
      lastSeenAt: _ago(hours: 3),
      createdAt: _ago(days: 255),
    ),
    UserModel(
      id: 'u7',
      email: 'berk.yucel@dentlink.com',
      fullName: 'Dr. Berk Yücel',
      username: 'berk_yucel',
      title: UserTitle.disHekimiGenelPratisyen,
      bio:
          'Genel pratisyen diş hekimi. Takım çalışmasına ve sürekli öğrenmeye inanıyorum.',
      university: 'Ege Üniversitesi',
      city: 'İzmir',
      experienceYears: 2,
      workplace: 'Özel Klinik',
      followersCount: 87,
      followingCount: 145,
      postsCount: 8,
      onboardingCompleted: true,
      lastSeenAt: _ago(hours: 12),
      createdAt: _ago(days: 150),
    ),
    UserModel(
      id: 'u8',
      email: 'selin.dogan@dentlink.com',
      fullName: 'Dr. Selin Doğan',
      username: 'selin_dogan',
      title: UserTitle.agizDisCeneCerrahisi,
      bio:
          'Ağız, diş ve çene cerrahı. Ortognatik cerrahi ve dental implant cerrahisi alanında uzmanım.',
      university: 'Akdeniz Üniversitesi',
      city: 'Antalya',
      experienceYears: 9,
      workplace: 'Akdeniz Üniversitesi Hastanesi',
      followersCount: 361,
      followingCount: 92,
      postsCount: 28,
      isVerified: true,
      onboardingCompleted: true,
      lastSeenAt: _ago(days: 1),
      createdAt: _ago(days: 470),
    ),
    UserModel(
      id: 'u9',
      email: 'furkan.ciftci@dentlink.com',
      fullName: 'Furkan Çiftçi',
      username: 'furkan_ciftci',
      title: UserTitle.ogrenci,
      bio:
          '5. sınıf diş hekimliği öğrencisi. Endodonti alanında uzmanlaşmak istiyorum.',
      university: 'İstanbul Üniversitesi',
      city: 'İstanbul',
      experienceYears: null,
      workplace: null,
      followersCount: 54,
      followingCount: 203,
      postsCount: 5,
      onboardingCompleted: true,
      lastSeenAt: _ago(hours: 1),
      createdAt: _ago(days: 90),
    ),
    UserModel(
      id: 'u10',
      email: 'mert.kaya@dentlink.com',
      fullName: 'Dr. Mert Kaya',
      username: 'mert_kaya',
      title: UserTitle.disHekimiGenelPratisyen,
      bio:
          'Genel Diş Hekimi. Oral diagnoz ve tedavi planlaması üzerine yoğunlaşıyorum.',
      university: 'İstanbul Üniversitesi',
      city: 'İstanbul',
      experienceYears: 6,
      workplace: 'Kaya Dental Klinik',
      followersCount: 112,
      followingCount: 45,
      postsCount: 10,
      isVerified: true,
      onboardingCompleted: true,
      lastSeenAt: _ago(minutes: 15),
      createdAt: _ago(days: 120),
    ),
  ];

  // ─── Yardımcı: ID'ye göre kullanıcı bul ──────────────────────────────────

  static UserModel userById(String id) => users.firstWhere((u) => u.id == id);

  // ─── Gönderiler ───────────────────────────────────────────────────────────

  static final List<PostModel> posts = [
    // ── VAKALAR (10) ─────────────────────────────────────────────────────
    PostModel(
      id: 'p1',
      userId: 'u1',
      type: PostType.casePost,
      title: 'Kalsifiye Kanal — 4 Kanallı Alt Molar Retreatment',
      content:
          'Hastam 42 yaşında erkek, 2 yıl önce başka bir klinikte kanal tedavisi yapılmış #46 diş. '
          'Periapikal ağrı ve radyolüsens ile başvurdu. CBCT incelemesinde 4 kanalın yalnızca 2'
          'sinin doldurulduğu ve MB2 kanalının tamamen atlandığı görüldü. '
          'ProTaper Gold retreatment eğeleriyle mevcut dolgu materyali uzaklaştırıldı. '
          'Kalsifiye MB2 kanalı ultrasonik uç yardımıyla bulundu ve #10 K-file ile negosiye edildi. '
          'Çalışma boyu CBCT destekli apex locator ile doğrulandı. WaveOne Gold Primary ile şekillendirildi, '
          'AH Plus siman ve guta perkа ile lateral kondansasyon uygulandı. '
          '6 aylık kontrolde tam iyileşme gözlemlendi.',
      branch: DentalBranch.endodonti,
      imageUrls: [],
      tags: [tags[0], tags[10]],
      likeCount: 87,
      commentCount: 14,
      bookmarkCount: 23,
      viewCount: 412,
      isLiked: false,
      isBookmarked: false,
      createdAt: _ago(days: 3),
      updatedAt: _ago(days: 3),
      author: userById('u1'),
    ),

    PostModel(
      id: 'p2',
      userId: 'u3',
      type: PostType.casePost,
      title: 'Kemik Kaybı Olan Bölgede All-on-4 İmplant Vakası',
      content:
          '67 yaşında dişsiz hasta. Uzun süreli total protez kullanımına bağlı ciddi kemik rezorpsiyonu mevcut. '
          'CBCT incelemesinde anterior mandibulada yeterli kemik yüksekliği tespit edildi. '
          'Posteriorda 30° açılı implantlar ile bone grafting ihtiyacı ortadan kaldırıldı. '
          'Cerrahi gün geçici sabit protez teslim edildi. '
          '6 aylık osseointegrasyon sonrası zirkonyum üst yapı yerleştirildi. '
          'Hasta fonksiyon ve estetikten son derece memnun. Torku kontrolü düzenli yapılıyor.',
      branch: DentalBranch.protetikDisTedavisi,
      imageUrls: [],
      tags: [tags[2], tags[3]],
      likeCount: 143,
      commentCount: 22,
      bookmarkCount: 51,
      viewCount: 689,
      isLiked: true,
      isBookmarked: true,
      createdAt: _ago(days: 5),
      updatedAt: _ago(days: 5),
      author: userById('u3'),
    ),

    PostModel(
      id: 'p3',
      userId: 'u2',
      type: PostType.casePost,
      title:
          'Yetişkinde İskelet Sınıf III — Camouflage ile Ortodontik Yaklaşım',
      content:
          '24 yaşında bayan hasta, belirgin alt çene öne uzanması şikayetiyle başvurdu. '
          'Sefalometrik analizde ANB: -3°, Wits appraisal: -5 mm. '
          'Hasta cerrahi tedaviyi reddetti. Dental kompanzasyon ile camuflage planlandı. '
          'Alt çenede premolar çekimi yapılarak kalabalık giderildi, alt ön dişler retrakte edildi. '
          'Üst çenede ekspansiyon uygulandı. 26 aylık aktif tedavi. '
          'Profil düzelmesi tatmin edici, oklüzyon Sınıf I elde edildi. Retansiyon aşamasında.',
      branch: DentalBranch.ortodonti,
      imageUrls: [],
      tags: [tags[5]],
      likeCount: 94,
      commentCount: 18,
      bookmarkCount: 31,
      viewCount: 523,
      isLiked: false,
      isBookmarked: false,
      createdAt: _ago(days: 7),
      updatedAt: _ago(days: 7),
      author: userById('u2'),
    ),

    PostModel(
      id: 'p4',
      userId: 'u5',
      type: PostType.casePost,
      title: 'İleri Periodontal Hastalık — Regeneratif Cerrahi + GTR',
      content:
          '38 yaşında erkek, tüm ağızda derin cep derinlikleri ve kemik kayıpları. '
          'Başlangıç tedavisi: SRP + sistemik antibiyotik. '
          'Re-değerlendirme sonrası #25-26 bölgesinde 8 mm\'lik vertikal kemik defekti tespit edildi. '
          'Open flap debridement + Emdogain uygulandı, biyoresorbabl membran (Bio-Gide) yerleştirildi. '
          'CBCT ile 6. ay kontrolü: %60 kemik kazanımı gözlemlendi. '
          'Hasta düzenli bakımda, yıllık kontroller planlandı.',
      branch: DentalBranch.periodontoloji,
      imageUrls: [],
      tags: [tags[6]],
      likeCount: 76,
      commentCount: 11,
      bookmarkCount: 28,
      viewCount: 367,
      isLiked: false,
      isBookmarked: false,
      createdAt: _ago(days: 10),
      updatedAt: _ago(days: 10),
      author: userById('u5'),
    ),

    PostModel(
      id: 'p5',
      userId: 'u4',
      type: PostType.casePost,
      title: '5 Yaşında Erken Çocukluk Çürüğü — Pulpotomi ve SSC',
      content:
          'Hastam 5 yaşında kız çocuğu, tüm üst süt ön dişlerde ve birinci büyük azılarda çürük. '
          'Dental anksiyete yüksek. Davranış yönetimi için Tell-Show-Do + nitrous oxide uygulandı. '
          '#64 ve #65\'te pulpotomi yapılarak MTA ile örtüldü, ardından SSC (paslanmaz çelik kron) yerleştirildi. '
          'Ön dişlerde estetik strip crown uygulandı. '
          'Ebeveyne beslenme danışmanlığı ve flor vernisi uygulaması hakkında bilgi verildi. '
          '3 aylık kontrolde çocuğun dental kaygısı önemli ölçüde azaldı.',
      branch: DentalBranch.pedodonti,
      imageUrls: [],
      tags: [tags[8], tags[10]],
      likeCount: 112,
      commentCount: 19,
      bookmarkCount: 37,
      viewCount: 498,
      isLiked: true,
      isBookmarked: false,
      createdAt: _ago(days: 12),
      updatedAt: _ago(days: 12),
      author: userById('u4'),
    ),

    PostModel(
      id: 'p6',
      userId: 'u6',
      type: PostType.casePost,
      title: 'Diş Renk Değişikliği — Kompozit ile Veneer Restorasyonu',
      content:
          '28 yaşında bayan hasta, florizis nedeniyle renk bozukluğu olan üst ön dişler. '
          'Minimal preparasyon (0.3-0.5 mm) planlandı; bazı dişlerde preparasyonsuz veneer yapıldı. '
          'Renk seçiminde Vita Linearguide 3D-Master kullanıldı. '
          'Kompozit: Empress Direct + Gaenial Anterior. Katmanlı teknik uygulandı. '
          'Bitirme ve cılalamada Sof-Lex diskleri ve Hawe Kerr Composi Pol. '
          'Hasta sonuçtan çok memnun. 18 aylık kontrolde yüzey pürüzsüzlüğü korunmakta.',
      branch: DentalBranch.restoratifDisTedavisi,
      imageUrls: [],
      tags: [tags[1], tags[4], tags[9]],
      likeCount: 158,
      commentCount: 26,
      bookmarkCount: 64,
      viewCount: 741,
      isLiked: false,
      isBookmarked: true,
      createdAt: _ago(days: 15),
      updatedAt: _ago(days: 15),
      author: userById('u6'),
    ),

    PostModel(
      id: 'p7',
      userId: 'u8',
      type: PostType.casePost,
      title: 'Gömülü Alt Yirmi Yaş Dişi — Koronektomi Tekniği',
      content:
          '22 yaşında erkek hasta, mandibulada derin gömülü #38. '
          'CBCT\'de diş köklerinin nervus alveolaris inferior ile iç içe geçtiği gözlemlendi. '
          'Konvansiyonel ekstraksiyon yerine koronektomi kararı alındı. '
          'Kron kısmı yavaşça uzaklaştırıldı, kökler 3 mm altta bırakıldı. '
          'Postoperatif parestezi görülmedi. '
          '1 yıllık takipte kökler kortikal kemiğe gömüldü, herhangi bir belirti yok.',
      branch: DentalBranch.agizDisCeneCerrahisi,
      imageUrls: [],
      tags: [tags[7]],
      likeCount: 99,
      commentCount: 15,
      bookmarkCount: 32,
      viewCount: 455,
      isLiked: false,
      isBookmarked: false,
      createdAt: _ago(days: 18),
      updatedAt: _ago(days: 18),
      author: userById('u8'),
    ),

    PostModel(
      id: 'p8',
      userId: 'u10',
      type: PostType.casePost,
      title: 'Liken Planus — Oral Mukoza Lezyonunun Takibi',
      content:
          '46 yaşında kadın hasta, yanakta beyaz ağ benzeri lezyonlar. '
          'Klinik muayene ve dermoskopik değerlendirme ile oral liken planus tanısı konuldu. '
          'İnkomplet lezyon — biyopsi alındı, patoloji retikular tip liken planus doğruladı. '
          'Sistemik hastalık (HCV, otoimmün bozukluk) araştırması yapıldı — negatif. '
          'Topikal steroid tedavisi başlandı (triamsinolon asetonit %0.1 orabase). '
          '3 aylık takipte lezyonlar belirgin şekilde küçüldü.',
      branch: DentalBranch.oralDiagnoz,
      imageUrls: [],
      tags: [],
      likeCount: 68,
      commentCount: 9,
      bookmarkCount: 19,
      viewCount: 289,
      isLiked: false,
      isBookmarked: false,
      createdAt: _ago(days: 20),
      updatedAt: _ago(days: 20),
      author: userById('u10'),
    ),

    PostModel(
      id: 'p9',
      userId: 'u3',
      type: PostType.casePost,
      title: 'Tam Dişsiz Hastada Implant Destekli Overdenture',
      content:
          '71 yaşında bayan hasta. Konvansiyonel total protez tutuculuk sorunu. '
          'Mandibula anterior bölgede 2 implant yerleştirildi. '
          'Ball attachment sistemiyle implant destekli alt tam protez yapıldı. '
          'Üst çenede konvansiyonel total protez güncellendi. '
          'Hasta yeme-içme fonksiyonunda dramatik iyileşme bildirdi. '
          'OHIP-EDENT skoru tedavi öncesi 38 → tedavi sonrası 12.',
      branch: DentalBranch.protetikDisTedavisi,
      imageUrls: [],
      tags: [tags[2]],
      likeCount: 121,
      commentCount: 17,
      bookmarkCount: 45,
      viewCount: 534,
      isLiked: false,
      isBookmarked: false,
      createdAt: _ago(days: 22),
      updatedAt: _ago(days: 22),
      author: userById('u3'),
    ),

    PostModel(
      id: 'p10',
      userId: 'u1',
      type: PostType.casePost,
      title: 'C-Şekilli Kanal Anatomisi — Alt 2. Molar',
      content:
          'Nadir görülen C-şekilli kanal morfolojisi içeren #47 vakası. '
          'Preoperatif CBCT ile C1 sınıfı (tam C-şekli) konfigürasyon doğrulandı. '
          'EDTA ile irrigasyon, düzenli agitasyon (EndoActivator). '
          'Isıyla yumuşatılan guta perka + AH Plus siman ile 3D dolgu tamamlandı. '
          'Vaka literatürdeki sınıflamalarla karşılaştırılarak dokümante edildi.',
      branch: DentalBranch.endodonti,
      imageUrls: [],
      tags: [tags[0]],
      likeCount: 74,
      commentCount: 12,
      bookmarkCount: 21,
      viewCount: 315,
      isLiked: false,
      isBookmarked: false,
      createdAt: _ago(days: 25),
      updatedAt: _ago(days: 25),
      author: userById('u1'),
    ),

    // ── SORULAR (10) ─────────────────────────────────────────────────────
    PostModel(
      id: 'p11',
      userId: 'u9',
      type: PostType.question,
      title:
          'ProTaper Gold vs. WaveOne Gold — Retreatment\'da hangisini tercih edersiniz?',
      content:
          'Klinik rotasyonumda bir retreatment vakasıyla karşılaştım. '
          'Asistanım ProTaper Gold retreatment eğelerini önerdi ama süpervizörüm WaveOne Gold\'u tercih etti. '
          'Her ikisinin retreatment performansını karşılaştıran güncel RCT var mı? '
          'Kalsifiye kanallarda hangisi daha etkili? Perforasyon riski açısından görüşleriniz neler?',
      branch: null,
      imageUrls: [],
      tags: [tags[0]],
      likeCount: 43,
      commentCount: 8,
      bookmarkCount: 12,
      viewCount: 287,
      isLiked: false,
      isBookmarked: false,
      isSolved: true,
      createdAt: _ago(days: 2),
      updatedAt: _ago(days: 2),
      author: userById('u9'),
    ),

    PostModel(
      id: 'p12',
      userId: 'u7',
      type: PostType.question,
      title: 'Gingival recession sınıflamasında Cairo\'yu kullanıyor musunuz?',
      content:
          'Miller sınıflaması yerine Cairo 2011 sınıflamasını kullananlar ne düşünüyor? '
          'Klinik kararlarınızı etkiliyor mu? '
          'RT1, RT2, RT3 gruplandırması prognoz tahmini açısından Miller\'dan üstün mü?',
      branch: null,
      imageUrls: [],
      tags: [tags[6]],
      likeCount: 31,
      commentCount: 6,
      bookmarkCount: 8,
      viewCount: 198,
      isLiked: false,
      isBookmarked: false,
      isSolved: false,
      createdAt: _ago(days: 4),
      updatedAt: _ago(days: 4),
      author: userById('u7'),
    ),

    PostModel(
      id: 'p13',
      userId: 'u4',
      type: PostType.question,
      title:
          'Çocuklarda dental fobia — hangi sedasyon protokolünü önerirsiniz?',
      content:
          '4 yaşında şiddetli dental fobisi olan bir hastam var. '
          'N2O yeterli olmadı. Midazolam oral sedasyon protokolünü uygulayan var mı? '
          'Doz, gözlem süresi ve ebeveyne ne kadar açıklama yapıyorsunuz?',
      branch: null,
      imageUrls: [],
      tags: [tags[8]],
      likeCount: 56,
      commentCount: 11,
      bookmarkCount: 18,
      viewCount: 341,
      isLiked: true,
      isBookmarked: false,
      isSolved: true,
      createdAt: _ago(days: 6),
      updatedAt: _ago(days: 6),
      author: userById('u4'),
    ),

    PostModel(
      id: 'p14',
      userId: 'u6',
      type: PostType.question,
      title:
          'Kompozit veneer vs. porselen veneer: estetik kalıcılık açısından fark var mı?',
      content:
          'Hasta florizis nedeniyle 8 ön dişte veneer istiyor. '
          'Bütçe kısıtlı, kompozit veneer önerdim. '
          'Uzun dönem renk stabilitesi ve yüzey pürüzlülüğü açısından literatürde ne var? '
          '5-10 yıl takipli çalışmalar hakkında görüşlerinizi alabilir miyim?',
      branch: null,
      imageUrls: [],
      tags: [tags[1], tags[4], tags[11]],
      likeCount: 67,
      commentCount: 14,
      bookmarkCount: 22,
      viewCount: 389,
      isLiked: false,
      isBookmarked: true,
      isSolved: false,
      createdAt: _ago(days: 8),
      updatedAt: _ago(days: 8),
      author: userById('u6'),
    ),

    PostModel(
      id: 'p15',
      userId: 'u9',
      type: PostType.question,
      title: 'Üniversite sonrası uzmanlık mı yoksa özel klinik mi?',
      content:
          'Mezuniyete 1 yılım kaldı. Uzmanlık sınavına hazırlanmak ile doğrudan özel klinik açmak arasında '
          'kalan arkadaşlar var mı? Finansal açıdan, mesleki gelişim açısından hangisini önerirsiniz? '
          'Endodonti düşünüyorum ama 5 yıl daha okumak zor görünüyor.',
      branch: null,
      imageUrls: [],
      tags: [],
      likeCount: 89,
      commentCount: 23,
      bookmarkCount: 31,
      viewCount: 612,
      isLiked: false,
      isBookmarked: false,
      isSolved: false,
      createdAt: _ago(days: 9),
      updatedAt: _ago(days: 9),
      author: userById('u9'),
    ),

    PostModel(
      id: 'p16',
      userId: 'u7',
      type: PostType.question,
      title: 'Lokal anestezi tutmayan hastada ne yapıyorsunuz?',
      content:
          'Akut pulpitisli hastada inferior alveolar blok + buccal + lingual infiltrasyon uyguladım, '
          'çalışmaya başladığımda hasta hala ağrı hissetti. '
          'Bu durumlarda intraligamentöz veya intrapulpal anestezi nasıl ve ne zaman yapmalı? '
          'Deneyimlerinizi paylaşır mısınız?',
      branch: null,
      imageUrls: [],
      tags: [tags[0]],
      likeCount: 52,
      commentCount: 16,
      bookmarkCount: 14,
      viewCount: 298,
      isLiked: false,
      isBookmarked: false,
      isSolved: true,
      createdAt: _ago(days: 11),
      updatedAt: _ago(days: 11),
      author: userById('u7'),
    ),

    PostModel(
      id: 'p17',
      userId: 'u2',
      type: PostType.question,
      title: 'İnvisalign\'da derin kapanış vakalarını nasıl ele alıyorsunuz?',
      content:
          'Derin kapanış vakasında alt ön dişlere yeterli attachment yerleştiremiyorum. '
          'Bite ramp kullanıyorum fakat bazı hastalarda yetersiz kalıyor. '
          'G7 protokolünden önce ve sonrası fark ettiniz mi? '
          'Alternatif olarak overlay ekleme konusunda tecrübeniz var mı?',
      branch: null,
      imageUrls: [],
      tags: [tags[5]],
      likeCount: 38,
      commentCount: 7,
      bookmarkCount: 9,
      viewCount: 213,
      isLiked: false,
      isBookmarked: false,
      isSolved: false,
      createdAt: _ago(days: 14),
      updatedAt: _ago(days: 14),
      author: userById('u2'),
    ),

    PostModel(
      id: 'p18',
      userId: 'u5',
      type: PostType.question,
      title: 'Antibiyotik profilaksisi: hangi hastaya, hangi ilaç?',
      content:
          'Periodontal cerrahi öncesi antibiyotik profilaksisi konusunda kafa karışıklığım var. '
          'AHA 2007 güncellemesinin ötesinde, günümüzde kılavuzlar ne söylüyor? '
          'Kalp kapak hastası, total diz/kalça protezi olan hastalarda protokolünüz nedir?',
      branch: null,
      imageUrls: [],
      tags: [tags[6]],
      likeCount: 61,
      commentCount: 13,
      bookmarkCount: 20,
      viewCount: 374,
      isLiked: false,
      isBookmarked: false,
      isSolved: false,
      createdAt: _ago(days: 16),
      updatedAt: _ago(days: 16),
      author: userById('u5'),
    ),

    PostModel(
      id: 'p19',
      userId: 'u8',
      type: PostType.question,
      title: 'Ortognatik cerrahi sonrası oklüzal uyum ne zaman tamamlanır?',
      content:
          'Bimaksiller ortognatik cerrahi geçiren hastamda 8 ay oldu, hala posterior açık kapanış var. '
          'Kondil relapsı mı, kas uyumsuzluğu mu, yoksa beklenen süreç mi? '
          'Bu aşamada ortodontist ne yapabilir? Cerrahi tekrar gerekir mi?',
      branch: null,
      imageUrls: [],
      tags: [tags[5]],
      likeCount: 45,
      commentCount: 9,
      bookmarkCount: 11,
      viewCount: 251,
      isLiked: false,
      isBookmarked: false,
      isSolved: false,
      createdAt: _ago(days: 19),
      updatedAt: _ago(days: 19),
      author: userById('u8'),
    ),

    PostModel(
      id: 'p20',
      userId: 'u10',
      type: PostType.question,
      title: 'Sjögren sendromu olan hastada ağız kuruluğu yönetimi',
      content:
          'Birincil Sjögren\'lu hastada ağız kuruluğu şiddetli. '
          'Yapay tükürük, pilokarpin, bilek uyarısı — hangisi daha etkili? '
          'Çürük profilaksisi için remineralizasyon protokolünüzü paylaşır mısınız? '
          'Flor varnisi frekansı ve ev bakımı önerileriniz neler?',
      branch: null,
      imageUrls: [],
      tags: [],
      likeCount: 49,
      commentCount: 10,
      bookmarkCount: 16,
      viewCount: 312,
      isLiked: false,
      isBookmarked: false,
      isSolved: false,
      createdAt: _ago(days: 21),
      updatedAt: _ago(days: 21),
      author: userById('u10'),
    ),
  ];

  // ─── Yardımcı: ID'ye göre post bul ───────────────────────────────────────

  static PostModel postById(String id) => posts.firstWhere((p) => p.id == id);

  // ─── Yorumlar (post ID'ye göre map) ──────────────────────────────────────

  static final Map<String, List<CommentModel>> comments = {
    'p1': [
      CommentModel(
        id: 'c1',
        postId: 'p1',
        userId: 'u5',
        content:
            'Mükemmel vaka sunumu. MB2 kanalının CBCT ile tespiti kritik bir adım. '
            'Sizin gibi vakalar ilerleyen dönemde retrospektif çalışmaya dönüştürülebilir.',
        likeCount: 12,
        isLiked: false,
        createdAt: _ago(days: 2, hours: 3),
        updatedAt: _ago(days: 2, hours: 3),
        author: userById('u5'),
      ),
      CommentModel(
        id: 'c2',
        postId: 'p1',
        userId: 'u9',
        content:
            'Kalsifiye MB2 kanalında ultrasonik uç kullanımı konusunda soru sormak istiyorum: '
            'Hangi güç seviyesinde çalıştınız? Perforasyon riski ne kadardı?',
        likeCount: 5,
        isLiked: false,
        createdAt: _ago(days: 2, hours: 2),
        updatedAt: _ago(days: 2, hours: 2),
        author: userById('u9'),
      ),
      CommentModel(
        id: 'c3',
        postId: 'p1',
        userId: 'u1',
        content:
            '@Furkan güç seviyesini minimal tuttum (3-4 watt). Sürekli irrigasyon altında çalışmak şart. '
            'Dentin duvarını takip etmek için büyütme sistemi (mikroskop) olmazsa olmaz.',
        likeCount: 18,
        isLiked: true,
        createdAt: _ago(days: 2, hours: 1),
        updatedAt: _ago(days: 2, hours: 1),
        author: userById('u1'),
      ),
    ],
    'p2': [
      CommentModel(
        id: 'c4',
        postId: 'p2',
        userId: 'u8',
        content:
            'Posterior açılı implant seçimi için kullandığınız simülasyon yazılımı hangisiydi? '
            'Nobel Clinician mı yoksa coDiagnostiX mi?',
        likeCount: 7,
        isLiked: false,
        createdAt: _ago(days: 4, hours: 5),
        updatedAt: _ago(days: 4, hours: 5),
        author: userById('u8'),
      ),
      CommentModel(
        id: 'c5',
        postId: 'p2',
        userId: 'u3',
        content:
            'Nobel Clinician kullandık. Cerrahi kılavuz üretimi için planlamayı fabrikaya gönderdik. '
            'Flapless cerrahi yapabildik, iyileşme süreci çok daha rahat oldu hasta için.',
        likeCount: 21,
        isLiked: false,
        createdAt: _ago(days: 4, hours: 4),
        updatedAt: _ago(days: 4, hours: 4),
        author: userById('u3'),
      ),
    ],
    'p11': [
      CommentModel(
        id: 'c6',
        postId: 'p11',
        userId: 'u1',
        content:
            'Kalsifiye kanallarda PTG Retreatment serisini tercih ediyorum. '
            'Daha agresif kesme kapasitesi var ama bu avantaj aynı zamanda risk de. '
            'Tecrübesiz ellerde dentin duvarını zedeleme riski WaveOne Gold\'dan daha yüksek.',
        isBestAnswer: true,
        likeCount: 34,
        isLiked: true,
        createdAt: _ago(days: 1, hours: 8),
        updatedAt: _ago(days: 1, hours: 8),
        author: userById('u1'),
      ),
      CommentModel(
        id: 'c7',
        postId: 'p11',
        userId: 'u5',
        content:
            'WaveOne Gold reciprokal hareket sayesinde kanal duvarında daha az stres oluşturuyor. '
            'Kavisli kanallarda tercihim kesinlikle WaveOne Gold. '
            'Bates et al. 2023 RCT\'si her ikisini de iyi buluyor ama WaveOne Gold daha az döngüsel yorulma.',
        likeCount: 19,
        isLiked: false,
        createdAt: _ago(days: 1, hours: 6),
        updatedAt: _ago(days: 1, hours: 6),
        author: userById('u5'),
      ),
    ],
    'p13': [
      CommentModel(
        id: 'c8',
        postId: 'p13',
        userId: 'u4',
        content:
            '4 yaşında midazolam oral sedasyon için 0.3-0.5 mg/kg dozunu kullanıyorum, '
            'maks 10 mg. Uygulama 20-30 dk önce yapılmalı. '
            'Pulsoksimetre ve kapnografi ile izleme şart. Ebeveyne onam formu mutlaka imzalatılmalı. '
            'Bakım veren de süreci anlamalı.',
        isBestAnswer: true,
        likeCount: 28,
        isLiked: false,
        createdAt: _ago(days: 5, hours: 3),
        updatedAt: _ago(days: 5, hours: 3),
        author: userById('u4'),
      ),
      CommentModel(
        id: 'c9',
        postId: 'p13',
        userId: 'u8',
        content:
            'Anestezi uzmanı desteğiyle propofol sedasyon da değerlendirebilirsiniz. '
            'Ama pedodonti kliniklerinde genellikle N2O + midazolam kombine kullanımı yeterli oluyor.',
        likeCount: 14,
        isLiked: false,
        createdAt: _ago(days: 5, hours: 1),
        updatedAt: _ago(days: 5, hours: 1),
        author: userById('u8'),
      ),
    ],
    'p16': [
      CommentModel(
        id: 'c10',
        postId: 'p16',
        userId: 'u1',
        content:
            'Akut pulpitiste Biers block (intraosseöz anestezi) çok etkili. '
            'X-tip sistemiyle inferior bloğu geçip kemik içine anestezi yapıyorum. '
            'Etkisi çok hızlı ve tam. Hasta rahatlıyor.',
        isBestAnswer: true,
        likeCount: 41,
        isLiked: true,
        createdAt: _ago(days: 10, hours: 4),
        updatedAt: _ago(days: 10, hours: 4),
        author: userById('u1'),
      ),
      CommentModel(
        id: 'c11',
        postId: 'p16',
        userId: 'u5',
        content:
            'İntraligamentöz enjeksiyon da hızlı ve etkili. '
            'Ultrashort igneyle yavaş enjeksiyon yapılmalı. Sistemik etki minimumdur.',
        likeCount: 22,
        isLiked: false,
        createdAt: _ago(days: 10, hours: 2),
        updatedAt: _ago(days: 10, hours: 2),
        author: userById('u5'),
      ),
    ],
  };

  // ─── Mesajlar & Konuşmalar ────────────────────────────────────────────────

  static final List<ConversationModel> conversations = [
    ConversationModel(
      id: 'conv1',
      otherUser: userById('u3'),
      lastMessageAt: _ago(minutes: 30),
      lastMessagePreview: 'Zirkonyum üst yapı için hangi labı kullanıyorsunuz?',
      unreadCount: 2,
    ),
    ConversationModel(
      id: 'conv2',
      otherUser: userById('u5'),
      lastMessageAt: _ago(hours: 3),
      lastMessagePreview: 'Tabii ki, Perşembe günü uygun olur.',
      unreadCount: 0,
    ),
    ConversationModel(
      id: 'conv3',
      otherUser: userById('u9'),
      lastMessageAt: _ago(days: 1),
      lastMessagePreview: 'Teşekkürler, çok faydalı oldu!',
      unreadCount: 0,
    ),
  ];

  static final Map<String, List<MessageModel>> messages = {
    'conv1': [
      MessageModel(
        id: 'm1',
        senderId: 'u3',
        receiverId: 'u1',
        content:
            'Merhaba Dr. Ahmet, All-on-4 vakamda zirkonyum üst yapı için hangi labı kullanıyorsunuz?',
        isRead: true,
        createdAt: _ago(hours: 2),
      ),
      MessageModel(
        id: 'm2',
        senderId: 'u1',
        receiverId: 'u3',
        content:
            'Merhaba, İstanbul\'da Denta-Lab ile çalışıyorum. Çok memnunum, kalite tutarlı.',
        isRead: true,
        createdAt: _ago(hours: 1, minutes: 45),
      ),
      MessageModel(
        id: 'm3',
        senderId: 'u3',
        receiverId: 'u1',
        content: 'Zirkonyum üst yapı için hangi labı kullanıyorsunuz?',
        isRead: false,
        createdAt: _ago(minutes: 30),
      ),
      MessageModel(
        id: 'm4',
        senderId: 'u3',
        receiverId: 'u1',
        content: 'Fiyat teklifi alabilir miyim acaba?',
        isRead: false,
        createdAt: _ago(minutes: 28),
      ),
    ],
    'conv2': [
      MessageModel(
        id: 'm5',
        senderId: 'u1',
        receiverId: 'u5',
        content:
            'Can bey, Perşembe öğleden sonra birlikte vaka değerlendirmek ister misiniz?',
        isRead: true,
        createdAt: _ago(hours: 4),
      ),
      MessageModel(
        id: 'm6',
        senderId: 'u5',
        receiverId: 'u1',
        content: 'Tabii ki, Perşembe günü uygun olur.',
        isRead: true,
        createdAt: _ago(hours: 3),
      ),
    ],
    'conv3': [
      MessageModel(
        id: 'm7',
        senderId: 'u9',
        receiverId: 'u1',
        content:
            'Dr. Ahmet hocam, kalsifiye kanal vakası için danışabilir miyim?',
        isRead: true,
        createdAt: _ago(days: 1, hours: 5),
      ),
      MessageModel(
        id: 'm8',
        senderId: 'u1',
        receiverId: 'u9',
        content: 'Tabii Furkan, dinliyorum. Ne tür bir sorunla karşılaştın?',
        isRead: true,
        createdAt: _ago(days: 1, hours: 4),
      ),
      MessageModel(
        id: 'm9',
        senderId: 'u9',
        receiverId: 'u1',
        content:
            'Anlattınız, çok yardımcı oldunuz. Teşekkürler, çok faydalı oldu!',
        isRead: true,
        createdAt: _ago(days: 1),
      ),
    ],
  };

  // ─── Bildirimler ──────────────────────────────────────────────────────────

  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n1',
      type: NotificationType.like,
      actor: userById('u3'),
      postId: 'p1',
      isRead: false,
      createdAt: _ago(minutes: 15),
    ),
    NotificationModel(
      id: 'n2',
      type: NotificationType.comment,
      actor: userById('u5'),
      postId: 'p1',
      isRead: false,
      createdAt: _ago(hours: 1),
    ),
    NotificationModel(
      id: 'n3',
      type: NotificationType.follow,
      actor: userById('u9'),
      isRead: false,
      createdAt: _ago(hours: 3),
    ),
    NotificationModel(
      id: 'n4',
      type: NotificationType.like,
      actor: userById('u2'),
      postId: 'p10',
      isRead: true,
      createdAt: _ago(hours: 6),
    ),
    NotificationModel(
      id: 'n5',
      type: NotificationType.comment,
      actor: userById('u4'),
      postId: 'p10',
      isRead: true,
      createdAt: _ago(hours: 8),
    ),
    NotificationModel(
      id: 'n6',
      type: NotificationType.message,
      actor: userById('u3'),
      isRead: true,
      createdAt: _ago(hours: 12),
    ),
    NotificationModel(
      id: 'n7',
      type: NotificationType.bestAnswer,
      actor: userById('u9'),
      commentId: 'c3',
      isRead: true,
      createdAt: _ago(days: 1),
    ),
    NotificationModel(
      id: 'n8',
      type: NotificationType.follow,
      actor: userById('u8'),
      isRead: true,
      createdAt: _ago(days: 2),
    ),
    NotificationModel(
      id: 'n9',
      type: NotificationType.like,
      actor: userById('u6'),
      postId: 'p1',
      isRead: true,
      createdAt: _ago(days: 3),
    ),
    NotificationModel(
      id: 'n10',
      type: NotificationType.badge,
      actor: userById('u1'),
      isRead: true,
      createdAt: _ago(days: 4),
    ),
  ];

  // ─── Rozetler ─────────────────────────────────────────────────────────────

  static final List<BadgeModel> userBadges = [
    BadgeModel(
      id: 'b1',
      name: 'Uzman Endodontist',
      description: 'Endodonti branşında 10\'dan fazla vaka paylaştı.',
      iconName: 'verified',
      earnedAt: _ago(days: 30),
    ),
    BadgeModel(
      id: 'b2',
      name: 'Topluluk Yıldızı',
      description: 'Gönderileri toplam 500+ beğeni aldı.',
      iconName: 'star',
      earnedAt: _ago(days: 60),
    ),
    BadgeModel(
      id: 'b3',
      name: 'Yardımsever',
      description: '5+ soruda "En İyi Cevap" seçildi.',
      iconName: 'emoji_events',
      earnedAt: _ago(days: 90),
    ),
  ];
}
