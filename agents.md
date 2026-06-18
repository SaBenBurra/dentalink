# DentLink — Diş Hekimleri İçin Sosyal Platform

> Diş hekimleri ve diş hekimliği öğrencileri için tasarlanmış, vaka paylaşımı, forum ve profesyonel ağ oluşturma odaklı mobil sosyal platform. LinkedIn'in diş hekimliği mesleğine özelleşmiş versiyonu.

> **📌 İlgili Dosya:** Geliştirme fazları ve ilerleme durumu için [`progress.md`](./progress.md) dosyasını da oku.

---

## 📱 Genel Bilgiler

| Özellik | Değer |
| --- | --- |
| **Proje Adı** | DentLink _(placeholder, değişebilir)_ |
| **Platform** | Mobil (Android + iOS) |
| **Framework** | Flutter |
| **Backend** | Supabase |
| **State Management** | Riverpod |
| **Navigasyon** | go_router |
| **Dil Desteği** | Çok dilli (Türkçe + İngilizce) |
| **Tema** | Karanlık & Aydınlık mod |
| **Tasarım Kaynağı** | Google Stitch → MCP Server → Flutter Widget |

---

## 👥 Kullanıcı Sistemi

### Kayıt & Giriş
- **Yöntemler:** E-posta, Google Sign-In, Telefon Numarası
- **Kullanıcı doğrulama (diploma vb.):** Şimdilik yok, ileride eklenecek

### Kullanıcı Profili

| Alan | Zorunlu | Açıklama |
| --- | --- | --- |
| Profil Fotoğrafı | Opsiyonel | Kullanıcı avatarı |
| Ad - Soyad | Zorunlu | Tam isim |
| Unvan | Zorunlu | Kayıt sırasında seçilir, sonradan değiştirilebilir |
| Biyografi | Opsiyonel | Kısa tanıtım metni |
| Üniversite | Opsiyonel | Mezun olunan / okunan üniversite |
| Şehir | Opsiyonel | Bulunduğu şehir |
| Deneyim Yılı | Opsiyonel | Mesleki deneyim süresi |
| Çalıştığı Klinik/Hastane | Opsiyonel | Aktif çalışma yeri |

### Unvanlar (Kayıt Sırasında Seçilir)
Kullanıcılar aşağıdaki unvanlardan birini seçer. Unvan sonradan değiştirilebilir.

- Öğrenci
- Diş Hekimi (Genel Pratisyen)
- Endodontist
- Ortodontist
- Periodontolog
- Protez Uzmanı
- Pedodontist
- Ağız, Diş ve Çene Cerrahı
- Ağız, Diş ve Çene Radyoloğu
- Oral Diagnoz Uzmanı
- Restoratif Diş Tedavisi Uzmanı

> **Not:** Bu liste genişletilebilir. Yeni unvanlar eklenebilir.

---

## 🧩 Temel Tasarım İlkeleri

> **⚠️ Bu bölümdeki ilkeler, projenin en başından itibaren tüm ekran, widget ve navigasyon tasarımlarında mutlaka uygulanmalıdır.**

### Genişletilebilirlik & Modülerlik (Extensibility-First)

Tüm arayüz bileşenleri, ileride kolayca güncellenebilecek, genişletilebilecek ve yeni öğeler eklenebilecek şekilde tasarlanmalıdır. Hiçbir ekran veya bileşen "son hali" olarak düşünülmemeli; her zaman evrilebilir bir yapıda inşa edilmelidir.

#### Kurallar

1. **Ekranlar Bileşen Tabanlı Olmalı:**
   - Her ekran, bağımsız ve yeniden kullanılabilir widget'lardan oluşmalı.
   - Bir ekrana yeni bir bölüm (section), kart veya buton eklemek mevcut kodu bozmadan yapılabilmeli.
   - Widget'lar birbirine sıkı sıkıya bağlı olmamalı (loose coupling).

2. **Yeni İçerik Türleri Kolayca Eklenebilmeli:**
   - Mevcut post türlerine (vaka, soru) yeni türler eklenebilecek şekilde soyutlama yapılmalı.
   - Feed, arama ve filtreleme mekanizmaları yeni içerik türlerini destekleyecek şekilde genelleştirilmiş olmalı.

3. **Ayarlar ve Profil Sayfaları Genişletilebilir Olmalı:**
   - Ayarlar sayfasına yeni seçenekler eklemek, sadece bir liste öğesi eklemekle mümkün olmalı.
   - Profil sayfasına yeni sekmeler veya bilgi alanları kolayca entegre edilebilmeli.

4. **Tasarım Sistemi Ölçeklenebilir Olmalı:**
   - Renk paleti, tipografi ve spacing değerleri merkezi bir tema dosyasından yönetilmeli.
   - Yeni bir tema veya renk varyasyonu eklemek minimum değişiklik gerektirmeli.

> **Özet:** "Bugün 5 sekmeli bir menü, yarın 6 sekmeli olabilir. Bugün 2 post türü var, yarın 4 olabilir. Bugün basit bir profil sayfası, yarın çok sekmeli bir profil olabilir." Bu yaklaşım, her ekran ve bileşen için geçerlidir.

---

## 📝 İçerik Türleri

### 1. Vaka (Case Post)
Diş hekimlerinin klinik vakalarını paylaştığı gönderi türü.

| Alan | Açıklama |
| --- | --- |
| Başlık | Vakanın kısa başlığı |
| Açıklama | Vakayı anlatan detaylı metin |
| Görseller | En fazla **10 görsel** eklenebilir |
| Branş | Her vakaya bir branş atanır (zorunlu) |
| Etiketler | Aranabilirliği artırmak için etiketler eklenir |

#### Branşlar (Vaka İçin)
- Pedodonti
- Endodonti
- Ortodonti
- Periodontoloji
- Protetik Diş Tedavisi
- Ağız, Diş ve Çene Cerrahisi
- Ağız, Diş ve Çene Radyolojisi
- Oral Diagnoz
- Restoratif Diş Tedavisi

#### Örnek Etiketler (Vaka İçin)
`dolgu`, `kanal tedavisi`, `estetik`, `kaplama`, `lamina`, `yer tutucu`, `implant`, `diş çekimi`, `apse`, `kök kanal tedavisi`, `veneer`, `zirkonyum`, `porselen`, `kompozit`, `amalgam`, `diş beyazlatma`, `gömülü diş`, `süt dişi`, `ortodontik tedavi`, `periodontal tedavi`

> **Not:** Etiketler kullanıcı tarafından serbest olarak eklenebilir; önceden tanımlı etiketler öneri olarak sunulacak.

---

### 2. Soru (Question Post)
Forum mantığında çalışan soru-cevap sistemi.

| Alan | Açıklama |
| --- | --- |
| Başlık | Sorunun başlığı |
| İçerik | Sorunun detaylı açıklaması |
| Etiketler | Konuyla ilgili etiketler |
| Görseller | Opsiyonel, destekleyici görseller |

#### Soru-Cevap Özellikleri
- Kullanıcılar soruları cevaplayabilir
- Soru sahibi bir cevabı **"En İyi Cevap"** olarak seçebilir
- En iyi cevap, diğer cevaplardan ayrı ve üstte gösterilir
- Cevaplara beğeni yapılabilir

---

### 3. İş İlanları (Job Posts)
> **Durum:** Planlandı, detayları netleşecek.
> **Açık Karar:** Ana sayfa akışında mı yoksa ayrı bir sayfada mı gösterilecek henüz kararlaştırılmadı.

---

## 🔄 Sosyal Medya Özellikleri

### Etkileşim
- **Beğeni (Like):** Vakalar ve sorular beğenilebilir
- **Yorum:** Vakalara ve sorulara yorum yapılabilir
- **Takip:** Kullanıcılar birbirini takip edebilir
- **Kaydetme (Bookmark):** Kullanıcılar vakaları ve soruları kaydedebilir

### Mesajlaşma (DM)
- Sadece **bire bir (DM)** mesajlaşma
- Grup mesajlaşması şimdilik yok

### Bildirimler (Push Notification)
- Beğeni bildirimi
- Yorum bildirimi
- Takip bildirimi
- Mesaj bildirimi

---

## 🏠 Ana Sayfa & Akış (Feed)

### Akış Sıralama Seçenekleri
Kullanıcı iki sıralama modu arasında **tab ile geçiş** yapabilir:

1. **Kronolojik:** En yeni gönderi en üstte
2. **Algoritmik:** Popülerlik, etkileşim, ilgi alanı gibi faktörlere göre sıralama

---

## 🔍 Keşfet & Arama

### Gelişmiş Arama (Full-Text Search)
- Vaka başlıklarında ve açıklamalarında tam metin arama
- Soru başlıklarında ve içeriklerinde tam metin arama

### Filtreler
- **Branşa göre** filtreleme
- **Etiketlere göre** filtreleme
- **Unvana göre** filtreleme (ör. sadece endodontistlerin paylaşımları)
- **İçerik türüne göre** filtreleme (vaka / soru)

### Kullanıcı Arama
- İsim, unvan veya üniversiteye göre kullanıcı arama

---

## 🏅 Rozetler & Başarımlar (Gamification)
Kullanıcıların motivasyonunu artırmak için rozet sistemi.

### Rozet Örnekleri
- **Uzman Rozeti:** Belirli bir branşta çok sayıda vaka paylaşan kullanıcılar
- **Popüler Rozet:** Yüksek etkileşim alan kullanıcılar
- **Yardımsever Rozeti:** Çok sayıda "En İyi Cevap" seçilen kullanıcılar
- **Yeni Üye Rozeti:** Platforma yeni katılan kullanıcılar

> **Not:** Rozet kuralları ve detayları geliştirme sürecinde belirlenecek.

---

## 🛡️ Moderasyon & Güvenlik

| Özellik | Durum |
| --- | --- |
| Kullanıcı Raporlama | İleride eklenecek |
| Kullanıcı Engelleme | İleride eklenecek |
| İçerik Moderasyonu | İleride eklenecek |
| Kullanıcı Doğrulama (Diploma) | İleride eklenecek |

---

## 🗄️ Backend Mimarisi (Supabase)

### Temel Tablolar

```
-- ─────────────────────────────────────────────────────────────────
-- DÜZELTME #13: branch serbest metin yerine PostgreSQL ENUM
-- ─────────────────────────────────────────────────────────────────
CREATE TYPE dental_branch AS ENUM (
  'pedodonti', 'endodonti', 'ortodonti', 'periodontoloji',
  'protetik_dis_tedavisi', 'agiz_dis_cene_cerrahisi',
  'agiz_dis_cene_radyolojisi', 'oral_diagnoz', 'restoratif_dis_tedavisi'
);

-- ─────────────────────────────────────────────────────────────────
-- DÜZELTME #10: bildirim tipi ENUM (best_answer + badge eklendi)
-- ─────────────────────────────────────────────────────────────────
CREATE TYPE notification_type AS ENUM (
  'like', 'comment', 'follow', 'message', 'best_answer', 'badge'
);

users
├── id (UUID, PK)
├── email
├── phone
├── full_name
├── username
├── avatar_url
├── title (unvan)
├── bio
├── university
├── city
├── experience_years
├── workplace (klinik/hastane)
├── followers_count      INT DEFAULT 0           -- #5 denormalize sayaç
├── following_count      INT DEFAULT 0           -- #5 denormalize sayaç
├── posts_count          INT DEFAULT 0           -- #5 denormalize sayaç
├── onboarding_completed BOOL DEFAULT false      -- #9 onboarding bir kez gösterilsin
├── is_verified          BOOL DEFAULT false      -- #9 Faz 6: diploma doğrulama
├── last_seen_at         TIMESTAMPTZ             -- #9 mesajlaşmada çevrimiçi göstergesi
├── notification_preferences JSONB DEFAULT '{}'  -- #9 hangi bildirimler gelsin
├── created_at
└── updated_at

posts
├── id (UUID, PK)
├── user_id (FK → users)
├── type (enum: 'case', 'question')
├── title
├── content
├── branch dental_branch (nullable, vaka için zorunlu) -- #13 ENUM tipine alındı
├── is_solved (soru için, en iyi cevap seçildi mi)
├── like_count      INT DEFAULT 0               -- #5 denormalize sayaç (trigger ile güncellenir)
├── comment_count   INT DEFAULT 0               -- #5 denormalize sayaç (trigger ile güncellenir)
├── bookmark_count  INT DEFAULT 0               -- #5 denormalize sayaç (trigger ile güncellenir)
├── view_count      INT DEFAULT 0               -- #6 algoritmik feed için görüntülenme sayısı
├── created_at
└── updated_at

post_images
├── id (UUID, PK)
├── post_id (FK → posts)
├── image_url
├── order_index
└── created_at

-- #6 Algoritmik feed: kim hangi postu gördü (dedup + sinyal)
post_views
├── user_id (FK → users)
├── post_id (FK → posts)
└── viewed_at
-- PRIMARY KEY (user_id, post_id)

tags
├── id (UUID, PK)
├── name        TEXT UNIQUE                     -- "Kanal Tedavisi"
├── slug        TEXT UNIQUE                     -- #7 "kanal-tedavisi" (URL-safe)
├── usage_count INT DEFAULT 0                   -- #7 popüler etiket önerisi için
└── created_at

post_tags
├── post_id (FK → posts)
└── tag_id  (FK → tags)
-- PRIMARY KEY (post_id, tag_id)                -- #12 composite PK, duplicate engeller

comments
├── id (UUID, PK)
├── post_id (FK → posts)
├── user_id (FK → users)
├── content
├── is_best_answer (boolean, soru postları için)
├── created_at
└── updated_at

likes
├── id (UUID, PK)
├── user_id    (FK → users)
├── post_id    (FK → posts,    nullable)
├── comment_id (FK → comments, nullable)
└── created_at
-- CHECK: (post_id IS NOT NULL AND comment_id IS NULL)   -- #2 tam olarak biri dolu olmalı
--     OR (post_id IS NULL AND comment_id IS NOT NULL)
-- UNIQUE (user_id, post_id)                             -- #2 aynı postu iki kez beğenemez
-- UNIQUE (user_id, comment_id)                          -- #2 aynı yorumu iki kez beğenemez

follows
├── follower_id  (FK → users)
├── following_id (FK → users)
└── created_at
-- PRIMARY KEY (follower_id, following_id)
-- CHECK: follower_id <> following_id                    -- #3 kendini takip engeli
-- UNIQUE (follower_id, following_id)                    -- #3 duplicate engeli

bookmarks
├── user_id (FK → users)
├── post_id (FK → posts)
└── created_at
-- PRIMARY KEY (user_id, post_id)
-- UNIQUE (user_id, post_id)                             -- #4 aynı postu iki kez kaydedemez

messages
├── id          (UUID, PK)
├── sender_id   (FK → users)
├── receiver_id (FK → users)
├── content
├── is_read
├── deleted_at  TIMESTAMPTZ NULL                -- #11 soft delete, "Bu mesaj silindi" göstergesi
└── created_at

-- #1 DÜZELTME: last_message_id kaldırıldı → dairesel FK çözüldü
-- last_message_id yerine last_message_at + last_message_preview kullanılır
-- Trigger: yeni mesaj insert edilince conversations güncellenir
conversations
├── id (UUID, PK)
├── user1_id             (FK → users)
├── user2_id             (FK → users)
├── last_message_at      TIMESTAMPTZ             -- #1 dairesel FK yerine timestamp
├── last_message_preview TEXT                    -- #1 son mesajın ilk 100 karakteri
├── user1_unread_count   INT DEFAULT 0           -- #14 N+1 sorgu yerine denormalize
├── user2_unread_count   INT DEFAULT 0           -- #14 N+1 sorgu yerine denormalize
└── updated_at
-- UNIQUE (user1_id, user2_id)

notifications
├── id         (UUID, PK)
├── user_id    (FK → users)
├── type       notification_type              -- #10 best_answer + badge eklendi
├── actor_id   (FK → users)
├── post_id    (FK → posts,    nullable)
├── comment_id (FK → comments, nullable)
├── is_read
└── created_at

badges
├── id (UUID, PK)
├── name
├── description
├── icon_url
└── criteria (JSON)

user_badges
├── user_id   (FK → users)
├── badge_id  (FK → badges)
└── earned_at
-- PRIMARY KEY (user_id, badge_id)

-- #8 Faz 5: FCM push bildirimleri için çok cihaz desteği
push_tokens
├── id       (UUID, PK)
├── user_id  (FK → users)
├── token    TEXT UNIQUE
├── platform TEXT  -- 'android' | 'ios'
└── created_at

-- #15 Faz 6: İş İlanları (iskelet, detaylar netleşecek)
job_posts
├── id          (UUID, PK)
├── user_id     (FK → users)  -- ilan veren
├── title       TEXT
├── description TEXT
├── city        TEXT
├── workplace   TEXT
├── is_active   BOOL DEFAULT true
├── created_at
└── updated_at

-- #16 Faz 6: Kullanıcı Engelleme
blocks
├── blocker_id (FK → users)
├── blocked_id (FK → users)
└── created_at
-- PRIMARY KEY (blocker_id, blocked_id)
-- CHECK: blocker_id <> blocked_id
-- UNIQUE (blocker_id, blocked_id)

-- #16 Faz 6: İçerik / Kullanıcı Raporlama
reports
├── id          (UUID, PK)
├── reporter_id (FK → users)
├── post_id     (FK → posts,    nullable)
├── comment_id  (FK → comments, nullable)
├── user_id     (FK → users,    nullable)  -- raporlanan kullanıcı
├── reason      TEXT
├── status      TEXT DEFAULT 'pending'     -- 'pending' | 'reviewed' | 'dismissed'
└── created_at
-- CHECK: tam olarak biri non-null (post_id / comment_id / user_id)
```

### Supabase Servisleri
- **Supabase Auth:** E-posta, Google, Telefon ile kimlik doğrulama
- **Supabase Database (PostgreSQL):** Tüm veri depolama
- **Supabase Storage:** Profil fotoğrafları, vaka görselleri
- **Supabase Realtime:** Mesajlaşma ve bildirimler için gerçek zamanlı abonelik
- **Supabase Edge Functions:** Bildirim gönderme, rozet hesaplama gibi sunucu tarafı işlemler

---

## 📁 Flutter Proje Yapısı (Önerilen)

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_dimensions.dart
│   │   └── supabase_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── dark_theme.dart
│   │   └── light_theme.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── date_formatter.dart
│   │   └── image_utils.dart
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   └── string_extensions.dart
│   └── l10n/
│       ├── app_localizations.dart
│       ├── intl_tr.arb
│       └── intl_en.arb
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── post_model.dart
│   │   ├── comment_model.dart
│   │   ├── message_model.dart
│   │   ├── conversation_model.dart
│   │   ├── notification_model.dart
│   │   ├── tag_model.dart
│   │   └── badge_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── post_repository.dart
│   │   ├── comment_repository.dart
│   │   ├── message_repository.dart
│   │   ├── notification_repository.dart
│   │   ├── search_repository.dart
│   │   └── badge_repository.dart
│   └── datasources/
│       └── supabase_datasource.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── post_provider.dart
│   ├── comment_provider.dart
│   ├── feed_provider.dart
│   ├── message_provider.dart
│   ├── notification_provider.dart
│   ├── search_provider.dart
│   ├── theme_provider.dart
│   └── locale_provider.dart
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── phone_verification_screen.dart
│   │   │   └── title_selection_screen.dart
│   │   └── widgets/
│   │       ├── auth_form.dart
│   │       └── social_login_buttons.dart
│   │
│   ├── feed/
│   │   ├── screens/
│   │   │   └── feed_screen.dart
│   │   └── widgets/
│   │       ├── feed_tabs.dart
│   │       ├── case_card.dart
│   │       └── question_card.dart
│   │
│   ├── post/
│   │   ├── screens/
│   │   │   ├── create_case_screen.dart
│   │   │   ├── create_question_screen.dart
│   │   │   ├── case_detail_screen.dart
│   │   │   └── question_detail_screen.dart
│   │   └── widgets/
│   │       ├── image_picker_grid.dart
│   │       ├── branch_selector.dart
│   │       ├── tag_input.dart
│   │       ├── comment_section.dart
│   │       ├── answer_card.dart
│   │       └── best_answer_badge.dart
│   │
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   └── followers_screen.dart
│   │   └── widgets/
│   │       ├── profile_header.dart
│   │       ├── profile_stats.dart
│   │       ├── profile_posts_tab.dart
│   │       └── badge_showcase.dart
│   │
│   ├── search/
│   │   ├── screens/
│   │   │   └── search_screen.dart
│   │   └── widgets/
│   │       ├── search_bar.dart
│   │       ├── filter_chips.dart
│   │       └── search_results.dart
│   │
│   ├── messaging/
│   │   ├── screens/
│   │   │   ├── conversations_screen.dart
│   │   │   └── chat_screen.dart
│   │   └── widgets/
│   │       ├── conversation_tile.dart
│   │       ├── message_bubble.dart
│   │       └── chat_input.dart
│   │
│   ├── notifications/
│   │   ├── screens/
│   │   │   └── notifications_screen.dart
│   │   └── widgets/
│   │       └── notification_tile.dart
│   │
│   ├── bookmarks/
│   │   ├── screens/
│   │   │   └── bookmarks_screen.dart
│   │   └── widgets/
│   │       └── bookmark_list.dart
│   │
│   └── settings/
│       ├── screens/
│       │   └── settings_screen.dart
│       └── widgets/
│           ├── theme_toggle.dart
│           └── language_selector.dart
│
└── shared/
    └── widgets/
        ├── app_bottom_nav_bar.dart
        ├── user_avatar.dart
        ├── loading_indicator.dart
        ├── error_widget.dart
        ├── empty_state.dart
        ├── tag_chip.dart
        ├── branch_chip.dart
        └── like_button.dart
```

---

## 🔗 Temel Bağımlılıklar (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x

  # Navigation
  go_router: ^14.x

  # Backend
  supabase_flutter: ^2.x

  # Localization
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.x

  # Image
  image_picker: ^1.x
  cached_network_image: ^3.x

  # UI Utilities
  shimmer: ^3.x                    # Loading placeholder
  flutter_svg: ^2.x                # SVG desteği

  # Push Notifications
  firebase_messaging: ^15.x       # FCM
  flutter_local_notifications: ^17.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.x
  build_runner: ^2.x
  flutter_lints: ^4.x
```

> **Not:** Bu bağımlılık listesi başlangıç için tasarlanmıştır. Geliştirme sürecinde ihtiyaç duyuldukça yeni bağımlılıklar eklenebilir.

---

## 📐 Navigasyon Yapısı

### Ana Navigasyon (Bottom Navigation Bar)
1. **Ana Sayfa (Feed)** — Akış görünümü
2. **Keşfet (Explore)** — Arama ve filtreleme
3. **Oluştur (+)** — Yeni vaka veya soru oluştur
4. **Mesajlar** — DM listesi
5. **Profil** — Kullanıcı profili

### Ekran Akışı (Screen Flow)

```
Splash Screen
    ├── Onboarding (ilk açılış)
    └── Auth Check
        ├── Login Screen
        │   ├── Register Screen
        │   │   └── Title Selection Screen
        │   └── Phone Verification Screen
        └── Main Shell (Bottom Nav)
            ├── Feed Screen
            │   ├── Case Detail Screen
            │   │   └── Comments / Full Image View
            │   └── Question Detail Screen
            │       └── Answers / Best Answer
            ├── Search/Explore Screen
            │   ├── Filter Results
            │   └── User Profile (other)
            ├── Create Post Screen
            │   ├── Create Case
            │   └── Create Question
            ├── Messages Screen
            │   └── Chat Screen
            └── Profile Screen
                ├── Edit Profile Screen
                ├── Followers/Following Screen
                ├── Bookmarks Screen
                ├── Badges Screen
                ├── Settings Screen
                │   ├── Theme Toggle
                │   ├── Language Selector
                │   └── Notifications Settings
                └── My Posts
```

---

## 🎨 Tasarım Notları

- Tüm tasarımlar **Google Stitch** ile hazırlanacak
- Tasarımlar **MCP Server** üzerinden agenta aktarılacak
- Agent, tasarımları **Flutter widget'larına** dönüştürecek
- Karanlık ve aydınlık mod için ayrı renk paletleri tanımlanacak
- Modern, temiz ve profesyonel bir tasarım dili hedefleniyor
- Tıbbi/dental bir tema rengi kullanılacak (ör. mavi-yeşil tonları)

---

## ⚠️ Açık Kararlar & Gelecek Tartışmalar

| Konu | Durum |
| --- | --- |
| Uygulama ismi (DentLink placeholder) | Karar verilecek |
| İş ilanları: akışta mı, ayrı sayfada mı? | Karar verilecek |
| Rozet kuralları ve kriterleri | Detaylandırılacak |
| Algoritmik feed detayları | Tasarlanacak |
| Görsel sıkıştırma / boyut limiti | Belirlenecek |
| Etiket öneri sistemi nasıl çalışacak? | Tasarlanacak |
