# DentLink — Diş Hekimleri İçin Sosyal Platform

> Diş hekimleri ve diş hekimliği öğrencileri için tasarlanmış, vaka paylaşımı, forum ve profesyonel ağ oluşturma odaklı mobil sosyal platform. LinkedIn'in diş hekimliği mesleğine özelleşmiş versiyonu.

> **📌 İlgili Dosya:** Geliştirme fazları ve ilerleme durumu için [`progress.md`](./progress.md) dosyasını da oku.

---

## 📱 Genel Bilgiler

| Özellik | Değer |
| --- | --- |
| **Proje Adı** | DentLink _(placeholder, değişebilir)_ |
| **Platform** | Mobil (Android + iOS) |
| **Framework** | Flutter (SDK ^3.12.2) |
| **Backend** | Supabase |
| **State Management** | Riverpod (flutter_riverpod + riverpod_annotation) |
| **Navigasyon** | go_router |
| **Dil Desteği** | Çok dilli (Türkçe + İngilizce, ARB tabanlı) |
| **Tema** | Karanlık & Aydınlık mod (SharedPreferences ile kalıcı) |
| **Tasarım Dili** | Glassmorphism + Material 3, Teal/Mint renk paleti |
| **Tipografi** | Plus Jakarta Sans |

---

## 🏗️ Mimari Kararlar

### Feature-Driven Architecture
Proje **özellik odaklı (feature-driven)** bir klasör yapısı kullanır. Her feature kendi `screens/`, `widgets/` ve `providers/` alt klasörlerine sahiptir.

### Repository Pattern (Clean Architecture)
Veri erişimi **abstract interface → concrete implementation** ayrımıyla yapılır:
- Her veri kaynağı için bir abstract repository (örn: `PostRepository`) tanımlanır
- Mock implementasyonu (`MockPostRepository`) ve gerçek implementasyon (`SupabaseAuthRepository`) ayrı dosyalardadır
- DI (Dependency Injection) `lib/data/providers/repository_providers.dart` üzerinden Riverpod ile yapılır
- **Şu an sadece Auth gerçek Supabase'e bağlı**, diğer tüm repository'ler mock implementasyon kullanır
- Faz 3'te mock'lar gerçek Supabase implementasyonlarıyla değiştirilecek — **UI koduna dokunmadan**

### Provider Katmanı Ayrımı
- **Global Provider'lar** (`lib/providers/`): Birden fazla feature tarafından kullanılan state (auth, feed, theme, locale vb.)
- **Feature Controller'ları** (`lib/features/*/providers/`): Tek bir feature'a özel iş mantığı (login_controller, create_case_controller vb.)

### Shared Widget & Extension Sistemi
- Birden fazla feature'da kullanılan widget'lar `lib/shared/widgets/` altında tutulur
- Model sınıflarına UI davranışı ekleyen extension'lar `lib/shared/extensions/` altında tutulur (renk, ikon, lokalizasyon)
- Bu sayede model sınıfları saf kalır (Material bağımlılığı olmaz)

---

## 👥 Kullanıcı Sistemi

### Kayıt & Giriş
- **Mevcut:** E-posta veya Telefon numarası ile şifresiz OTP doğrulama (Supabase Auth, gerçek bağlantı aktif)
- **Planlanıyor:** Google Sign-In (Faz 3)
- **Kullanıcı doğrulama (diploma vb.):** Şimdilik yok (Faz 6)

### Giriş Akışı
1. Kullanıcı e-posta veya telefon numarası girer
2. 6 haneli OTP kodu gönderilir
3. Kullanıcı kodu girer → doğrulama başarılı → feed'e yönlendirilir
4. İlk kez kayıt oluyorsa → 3 adımlı kayıt sihirbazına yönlendirilir

### Kayıt Akışı (3 Adımlı)
1. **Adım 1 — "Sizi Tanıyalım":** Ad-Soyad girişi + Unvan seçimi (2 sütunlu kart ızgarası)
2. **Adım 2 — "Mesleki Bilgiler":** Üniversite, Şehir, Klinik/Hastane, Deneyim Yılı (opsiyonel)
3. **Adım 3 — "Profil Detayları":** Profil fotoğrafı (kamera/galeri/hazır avatar) + Biyografi

### Kullanıcı Profili

| Alan | Zorunlu | Açıklama |
| --- | --- | --- |
| Profil Fotoğrafı | Opsiyonel | Kullanıcı avatarı (Supabase Storage'a yükleniyor) |
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

> **Not:** Bu liste `UserTitle` enum'unda tanımlıdır ve genişletilebilir.

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
   - `PostModel` sealed class yapısı ve `PostCardFactory` pattern'i bu amaçla tasarlanmıştır.
   - Feed, arama ve filtreleme mekanizmaları yeni içerik türlerini destekleyecek şekilde genelleştirilmiş olmalı.

3. **Ayarlar ve Profil Sayfaları Genişletilebilir Olmalı:**
   - Ayarlar sayfasına yeni seçenekler eklemek, sadece `_buildSections` listesine yeni bir `SettingsSection` eklemekle mümkün.
   - Profil sayfasına yeni sekmeler veya bilgi alanları kolayca entegre edilebilmeli.

4. **Tasarım Sistemi Ölçeklenebilir Olmalı:**
   - Renk paleti, tipografi ve spacing değerleri merkezi tema dosyalarından yönetilir (`app_colors.dart`, `app_text_styles.dart`, `app_dimensions.dart`).
   - Glassmorphism parametreleri `GlassThemeExtension` ile tokenize edilmiştir.
   - Yeni bir tema veya renk varyasyonu eklemek minimum değişiklik gerektirir.

> **Özet:** "Bugün 5 sekmeli bir menü, yarın 6 sekmeli olabilir. Bugün 2 post türü var, yarın 4 olabilir. Bugün basit bir profil sayfası, yarın çok sekmeli bir profil olabilir." Bu yaklaşım, her ekran ve bileşen için geçerlidir.

---

## 📝 İçerik Türleri

### 1. Vaka (Case Post) — ✅ Mevcut
Diş hekimlerinin klinik vakalarını paylaştığı gönderi türü.

| Alan | Açıklama |
| --- | --- |
| Başlık | Vakanın kısa başlığı |
| Açıklama | Vakayı anlatan detaylı metin |
| Görseller | En fazla **10 görsel** eklenebilir |
| Branş | Her vakaya bir branş atanır (zorunlu) |
| Etiketler | Aranabilirliği artırmak için etiketler eklenir |

#### Branşlar (Vaka İçin)
`DentalBranch` enum'unda tanımlıdır:
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

### 2. Soru (Question Post) — ✅ Mevcut
Forum mantığında çalışan soru-cevap sistemi.

| Alan | Açıklama |
| --- | --- |
| Başlık | Sorunun başlığı |
| İçerik | Sorunun detaylı açıklaması |
| Etiketler | Konuyla ilgili etiketler |
| Görseller | Opsiyonel (maks 4), destekleyici görseller |

#### Soru-Cevap Özellikleri
- Kullanıcılar soruları cevaplayabilir
- Soru sahibi bir cevabı **"En İyi Cevap"** olarak seçebilir (yeşil çerçeve + onay rozeti)
- En iyi cevap, diğer cevaplardan ayrı ve üstte gösterilir
- Cevaplara beğeni yapılabilir

---

### 3. İş İlanları (Job Posts) — 📅 Faz 6 (Henüz kodda yok)
Kliniklerin veya hastanelerin personel ve hekim arayışları için paylaştığı ilan türü.

| Alan | Açıklama |
| --- | --- |
| Başlık | İlanın kısa başlığı |
| Açıklama | İşin detayları ve beklentiler |
| Şehir / Konum | Çalışma yeri |
| Kurum | İlanı veren klinik veya hastane |

---

### 4. Malzeme Alış/Satışı (Marketplace Posts) — 📅 Faz 6 (Henüz kodda yok)
Diş hekimlerinin dental cihaz, ekipman ve malzemelerini alıp sattığı pazar yeri gönderileri.

| Alan | Açıklama |
| --- | --- |
| Başlık | Ürünün adı ve modeli |
| Açıklama | Ürünün durumu ve detayları |
| Fiyat | Talep edilen ücret |
| Görseller | Ürün fotoğrafları |

> **Not:** İçerik yapısı genişletilebilir (Extensibility-First) olarak tasarlanmıştır. `PostModel` sealed class yapısına yeni varyantlar eklenerek yeni post türleri kolayca entegre edilebilir.

---

## 🔄 Sosyal Medya Özellikleri

### Etkileşim
- **Beğeni (Like):** Vakalar, sorular ve yorumlar beğenilebilir (optimistik güncelleme ile)
- **Yorum:** Vakalara ve sorulara yorum yapılabilir
- **Takip:** Kullanıcılar birbirini takip edebilir
- **Kaydetme (Bookmark):** Kullanıcılar vakaları ve soruları kaydedebilir (swipe-to-dismiss ile kaldırılabilir)

### Mesajlaşma (DM)
- Sadece **bire bir (DM)** mesajlaşma
- Mesaj baloncukları (gönderilen/alınan ayrımı), zaman damgası, görsel mesaj desteği
- Grup mesajlaşması şimdilik yok

### Bildirimler
- Beğeni bildirimi
- Yorum bildirimi
- Takip bildirimi
- Mesaj bildirimi
- En İyi Cevap bildirimi
- Rozet kazanma bildirimi
- Tümünü okundu işaretle özelliği

> **Not:** Push notification (FCM) henüz implemente edilmedi. Şu an uygulama içi bildirimler mock data ile çalışıyor.

---

## 🏠 Ana Sayfa & Akış (Feed)

### Akış Filtreleme
Kullanıcı üç sekme arasında geçiş yapabilir:

1. **Tümü:** Tüm gönderi türleri (vakalar + sorular) karışık
2. **Vakalar:** Sadece vaka paylaşımları
3. **Sorular:** Sadece sorular

> **Not:** Provider seviyesinde `FeedMode.chronological` ve `FeedMode.algorithmic` tanımlıdır ancak UI'da henüz mod geçişi düğmesi eklenmemiştir. Faz 4'te eklenecek.

### Feed Özellikleri
- Pull-to-refresh (aşağı çekip yenileme)
- Shimmer efektli iskelet yükleyici
- Daralan/kayan AppBar (floating pill animasyonu, glassmorphism blur)
- Çift tıklama ile beğeni animasyonu (post media üzerinde)

---

## 🔍 Keşfet & Arama

### Gelişmiş Arama
- Vaka ve soru başlıklarında/içeriklerinde arama
- Kullanıcı arama (isim, unvan, üniversite)
- 2 sekmeli sonuç gösterimi (Gönderiler / Kullanıcılar)
- Debounce (500ms) ile performanslı arama

### Filtreler
- **Branşa göre** filtreleme (`DentalBranch` popup menü)
- **İçerik türüne göre** filtreleme (vaka / soru)
- Filtre chip'leri temizlenebilir

---

## 🏅 Rozetler & Başarımlar (Gamification)
Kullanıcıların motivasyonunu artırmak için rozet sistemi.

### Rozet Örnekleri
- **Uzman Rozeti:** Belirli bir branşta çok sayıda vaka paylaşan kullanıcılar
- **Popüler Rozet:** Yüksek etkileşim alan kullanıcılar
- **Yardımsever Rozeti:** Çok sayıda "En İyi Cevap" seçilen kullanıcılar
- **Yeni Üye Rozeti:** Platforma yeni katılan kullanıcılar

> **Not:** Rozet UI'ı profil ekranında vitrin olarak mevcut (`BadgeShowcase` widget'ı). Rozet kazanma kuralları ve backend mantığı Faz 5'te geliştirilecek.

---

## 🛡️ Moderasyon & Güvenlik

| Özellik | Durum |
| --- | --- |
| Kullanıcı Raporlama | Faz 6 |
| Kullanıcı Engelleme | Faz 6 |
| İçerik Moderasyonu | Faz 6 |
| Kullanıcı Doğrulama (Diploma) | Faz 6 |

---

## 🗄️ Backend Mimarisi (Supabase)

### Mevcut Backend Durumu
- **Supabase Auth:** ✅ Aktif — E-posta ve telefon ile OTP doğrulama çalışıyor
- **Supabase Storage:** ✅ Aktif — Profil fotoğrafı yükleme (avatars bucket)
- **Supabase Database:** ⏳ Faz 3'te aktifleştirilecek — Tablo şeması aşağıda tanımlı
- **Supabase Realtime:** ⏳ Faz 3'te mesajlaşma ve bildirimler için bağlanacak
- **Supabase Edge Functions:** ⏳ Faz 5'te bildirim gönderme, rozet hesaplama için

### Temel Tablolar

```sql
-- ─────────────────────────────────────────────────────────────────
-- PostgreSQL ENUM Tipleri
-- ─────────────────────────────────────────────────────────────────
CREATE TYPE dental_branch AS ENUM (
  'pedodonti', 'endodonti', 'ortodonti', 'periodontoloji',
  'protetik_dis_tedavisi', 'agiz_dis_cene_cerrahisi',
  'agiz_dis_cene_radyolojisi', 'oral_diagnoz', 'restoratif_dis_tedavisi'
);

CREATE TYPE notification_type AS ENUM (
  'like', 'comment', 'follow', 'message', 'best_answer', 'badge'
);

-- ─────────────────────────────────────────────────────────────────

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
├── followers_count      INT DEFAULT 0           -- denormalize sayaç
├── following_count      INT DEFAULT 0           -- denormalize sayaç
├── posts_count          INT DEFAULT 0           -- denormalize sayaç
├── onboarding_completed BOOL DEFAULT false
├── is_verified          BOOL DEFAULT false      -- Faz 6: diploma doğrulama
├── last_seen_at         TIMESTAMPTZ             -- mesajlaşmada çevrimiçi göstergesi
├── notification_preferences JSONB DEFAULT '{}'  -- hangi bildirimler gelsin
├── created_at
└── updated_at

posts
├── id (UUID, PK)
├── user_id (FK → users)
├── type (enum: 'case', 'question')             -- Faz 6'da 'job', 'marketplace' eklenecek
├── title
├── content
├── branch dental_branch (nullable, vaka için zorunlu)
├── is_solved (soru için, en iyi cevap seçildi mi)
├── like_count      INT DEFAULT 0               -- denormalize sayaç (trigger ile güncellenir)
├── comment_count   INT DEFAULT 0               -- denormalize sayaç (trigger ile güncellenir)
├── bookmark_count  INT DEFAULT 0               -- denormalize sayaç (trigger ile güncellenir)
├── view_count      INT DEFAULT 0               -- algoritmik feed için
├── created_at
└── updated_at

post_images
├── id (UUID, PK)
├── post_id (FK → posts)
├── image_url
├── order_index
└── created_at

post_views
├── user_id (FK → users)
├── post_id (FK → posts)
└── viewed_at
-- PRIMARY KEY (user_id, post_id)

tags
├── id (UUID, PK)
├── name        TEXT UNIQUE
├── slug        TEXT UNIQUE                     -- URL-safe slug
├── usage_count INT DEFAULT 0                   -- popüler etiket önerisi için
└── created_at

post_tags
├── post_id (FK → posts)
└── tag_id  (FK → tags)
-- PRIMARY KEY (post_id, tag_id)

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
-- CHECK: (post_id IS NOT NULL AND comment_id IS NULL)
--     OR (post_id IS NULL AND comment_id IS NOT NULL)
-- UNIQUE (user_id, post_id)
-- UNIQUE (user_id, comment_id)

follows
├── follower_id  (FK → users)
├── following_id (FK → users)
└── created_at
-- PRIMARY KEY (follower_id, following_id)
-- CHECK: follower_id <> following_id

bookmarks
├── user_id (FK → users)
├── post_id (FK → posts)
└── created_at
-- PRIMARY KEY (user_id, post_id)

messages
├── id          (UUID, PK)
├── sender_id   (FK → users)
├── receiver_id (FK → users)
├── content
├── is_read
├── deleted_at  TIMESTAMPTZ NULL                -- soft delete
└── created_at

conversations
├── id (UUID, PK)
├── user1_id             (FK → users)
├── user2_id             (FK → users)
├── last_message_at      TIMESTAMPTZ
├── last_message_preview TEXT                    -- son mesajın ilk 100 karakteri
├── user1_unread_count   INT DEFAULT 0
├── user2_unread_count   INT DEFAULT 0
└── updated_at
-- UNIQUE (user1_id, user2_id)

notifications
├── id         (UUID, PK)
├── user_id    (FK → users)
├── type       notification_type
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

-- Faz 5: FCM push bildirimleri için çok cihaz desteği
push_tokens
├── id       (UUID, PK)
├── user_id  (FK → users)
├── token    TEXT UNIQUE
├── platform TEXT  -- 'android' | 'ios'
└── created_at

-- Faz 6: Kullanıcı Engelleme
blocks
├── blocker_id (FK → users)
├── blocked_id (FK → users)
└── created_at
-- PRIMARY KEY (blocker_id, blocked_id)
-- CHECK: blocker_id <> blocked_id

-- Faz 6: İçerik / Kullanıcı Raporlama
reports
├── id          (UUID, PK)
├── reporter_id (FK → users)
├── post_id     (FK → posts,    nullable)
├── comment_id  (FK → comments, nullable)
├── user_id     (FK → users,    nullable)
├── reason      TEXT
├── status      TEXT DEFAULT 'pending'     -- 'pending' | 'reviewed' | 'dismissed'
└── created_at
-- CHECK: tam olarak biri non-null (post_id / comment_id / user_id)
```

---

## 📁 Flutter Proje Yapısı (Mevcut)

```
lib/
├── main.dart                              # Uygulama giriş noktası, Supabase init, ProviderScope
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                # Renk paleti (primary teal, surface, border, shimmer vb.)
│   │   ├── app_text_styles.dart           # Tipografi (Plus Jakarta Sans, Display→Label arası)
│   │   └── app_dimensions.dart            # Spacing, radius, avatar boyutları, animasyon süreleri
│   ├── theme/
│   │   ├── app_theme.dart                 # Material 3 ThemeData factory (light + dark)
│   │   ├── light_theme.dart               # Aydınlık mod renk şeması
│   │   ├── dark_theme.dart                # Karanlık mod renk şeması
│   │   └── glass_theme.dart               # GlassThemeExtension (blur, tint, frost tokenleri)
│   ├── router/
│   │   └── app_router.dart                # GoRouter yapılandırması, tüm rotalar, auth guard
│   ├── utils/
│   │   ├── number_formatter.dart          # Kompakt metrik formatlama (1200 → 1.2K)
│   │   ├── string_utils.dart              # Username üretici, Türkçe slug temizleme
│   │   └── validators.dart                # TR telefon, e-posta, OTP regex validasyonları
│   ├── extensions/
│   │   └── context_extensions.dart        # context.l10n, context.theme, context.isDark vb.
│   └── l10n/
│       ├── l10n.dart                      # Desteklenen locale'ler ve yardımcılar
│       ├── intl_tr.arb                    # Türkçe çeviriler (~93 anahtar)
│       ├── intl_en.arb                    # İngilizce çeviriler (~37 anahtar, eksik)
│       └── generated/                     # Otomatik üretilen lokalizasyon dosyaları
│
├── data/
│   ├── models/
│   │   ├── enums.dart                     # UserTitle, DentalBranch, PostType, NotificationType
│   │   ├── user_model.dart                # Kullanıcı profili modeli
│   │   ├── post_model.dart                # PostModel sealed class (CasePostModel, QuestionPostModel)
│   │   ├── comment_model.dart             # Yorum modeli (isBestAnswer dahil)
│   │   ├── conversation_model.dart        # Sohbet modeli
│   │   ├── message_model.dart             # Mesaj modeli (soft delete dahil)
│   │   ├── notification_model.dart        # Bildirim modeli
│   │   ├── tag_model.dart                 # Etiket modeli
│   │   └── badge_model.dart               # Rozet modeli
│   ├── repositories/
│   │   ├── auth_repository.dart           # Abstract interface
│   │   ├── post_repository.dart           # Abstract (IFeed, ISearch, IBookmark, IPostAction)
│   │   ├── comment_repository.dart        # Abstract interface
│   │   ├── message_repository.dart        # Abstract interface
│   │   ├── notification_repository.dart   # Abstract interface
│   │   ├── user_repository.dart           # Abstract interface
│   │   ├── supabase_auth_repository.dart  # ✅ GERÇEK Supabase implementasyonu
│   │   ├── mock_auth_repository.dart      # Mock implementasyon
│   │   ├── mock_post_repository.dart      # Mock implementasyon
│   │   ├── mock_comment_repository.dart   # Mock implementasyon
│   │   ├── mock_message_repository.dart   # Mock implementasyon
│   │   ├── mock_notification_repository.dart # Mock implementasyon
│   │   ├── mock_user_repository.dart      # Mock implementasyon
│   │   ├── otp_send_limiter.dart          # OTP rate limiter (SharedPreferences)
│   │   └── otp_cooldown_exception.dart    # OTP cooldown exception sınıfı
│   ├── datasources/
│   │   └── mock_datasource.dart           # Merkezi mock veri kaynağı (1182 satır)
│   └── providers/
│       └── repository_providers.dart      # Riverpod DI — mock/real repository seçimi
│
├── providers/                             # Global state provider'ları
│   ├── auth_provider.dart                 # AuthNotifier, currentUserProvider, authRedirectHoldProvider
│   ├── feed_provider.dart                 # FeedNotifier (FeedMode: chronological/algorithmic)
│   ├── post_provider.dart                 # PostDetailNotifier, userPostsProvider
│   ├── bookmark_provider.dart             # BookmarkNotifier (optimistik güncelleme)
│   ├── comment_provider.dart              # CommentsNotifier (yorum ekleme, beğeni, en iyi cevap)
│   ├── search_provider.dart               # SearchNotifier (paralel post + kullanıcı arama)
│   ├── user_provider.dart                 # UserProfileNotifier, followers/following, badges
│   ├── message_provider.dart              # ConversationsNotifier, ChatNotifier, totalUnread
│   ├── notification_provider.dart         # NotificationsNotifier, unreadCount
│   ├── theme_provider.dart                # ThemeModeNotifier (system/light/dark)
│   └── locale_provider.dart               # LocaleModeNotifier (tr/en)
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   └── login_step.dart
│   │   ├── providers/
│   │   │   ├── login_controller.dart
│   │   │   └── register_controller.dart
│   │   ├── screens/
│   │   │   ├── login_screen.dart          # OTP tabanlı giriş (e-posta/telefon → 6 haneli kod)
│   │   │   └── register_screen.dart       # 3 adımlı kayıt sihirbazı
│   │   └── widgets/
│   │       ├── login_background.dart      # Glassmorphism gradient arka plan
│   │       ├── login_logo_header.dart     # Özel diş logosu (CustomPainter)
│   │       ├── login_email_phone_input.dart # E-posta/telefon giriş alanı
│   │       ├── login_otp_input.dart       # 6 haneli OTP kutuları + animasyonlar
│   │       ├── register_header.dart       # İlerleme çubuğu + adım sayacı
│   │       ├── register_bottom_actions.dart # Geri/İleri navigasyon butonları
│   │       ├── register_step_one.dart     # Ad + Unvan kart ızgarası
│   │       ├── register_step_two.dart     # Mesleki bilgiler formu
│   │       ├── register_step_three.dart   # Profil fotoğrafı + biyografi
│   │       └── register_dialog.dart       # Kayıt tamamlama onay penceresi
│   │
│   ├── feed/
│   │   ├── screens/
│   │   │   └── feed_screen.dart           # 3 sekmeli feed (Tümü/Vakalar/Sorular)
│   │   └── widgets/
│   │       ├── feed_screen_app_bar.dart   # Daralan/kayan floating pill AppBar
│   │       ├── feed_list.dart             # PostCardFactory ile gönderi listesi
│   │       └── feed_skeleton.dart         # Shimmer iskelet yükleyici
│   │
│   ├── post/
│   │   ├── providers/
│   │   │   ├── create_case_controller.dart
│   │   │   └── create_question_controller.dart
│   │   ├── screens/
│   │   │   ├── create_case_screen.dart    # Vaka oluşturma formu
│   │   │   ├── create_question_screen.dart # Soru oluşturma formu
│   │   │   ├── case_detail_screen.dart    # Vaka detay (galeri, yorumlar, etkileşim)
│   │   │   └── question_detail_screen.dart # Soru detay (cevaplar, en iyi cevap)
│   │   └── widgets/
│   │       ├── branch_selector.dart       # Branş seçici modal bottom sheet
│   │       ├── image_picker_grid.dart     # Görsel seçici grid
│   │       ├── tag_input.dart             # Etiket girişi (chip'ler)
│   │       └── detail/
│   │           ├── case_detail_comments.dart       # Yorum listesi + beğeni
│   │           ├── question_detail_answers.dart    # Cevap listesi + en iyi cevap
│   │           ├── post_detail_author_info.dart    # Yazar bilgisi + takip butonu
│   │           └── post_detail_interaction_bar.dart # Beğeni + yorum sayısı çubuğu
│   │
│   ├── profile/
│   │   ├── providers/
│   │   │   └── edit_profile_controller.dart
│   │   ├── screens/
│   │   │   ├── profile_screen.dart        # Profil (header, stats, postlar, rozetler)
│   │   │   ├── edit_profile_screen.dart   # Profil düzenleme formu
│   │   │   └── followers_screen.dart      # Takipçiler / Takip Edilenler (2 sekmeli)
│   │   └── widgets/
│   │       ├── profile_header.dart        # Avatar, isim, bio, konum, düzenle butonu
│   │       ├── profile_stats.dart         # Gönderi, takipçi, takip sayaçları
│   │       ├── profile_posts_tab.dart     # Sekmeli post listesi (Vakalar/Sorular)
│   │       ├── badge_showcase.dart        # Rozet vitrini (yatay kaydırılabilir)
│   │       └── mutual_followers_widget.dart # Ortak takipçi gösterimi
│   │
│   ├── search/
│   │   ├── screens/
│   │   │   └── search_screen.dart         # Arama ekranı (debounce, 2 sekmeli sonuç)
│   │   └── widgets/
│   │       ├── search_bar.dart            # Özel arama çubuğu
│   │       ├── filter_chips.dart          # Branş + içerik tipi filtre chip'leri
│   │       └── search_results.dart        # Gönderi ve kullanıcı sonuç listeleri
│   │
│   ├── messaging/
│   │   ├── screens/
│   │   │   ├── conversations_screen.dart  # Sohbet listesi (arama, okunmamış sayısı)
│   │   │   └── chat_screen.dart           # Chat detay (baloncuklar, gönderme, eklenti)
│   │   └── widgets/
│   │       ├── conversation_tile.dart     # Sohbet satır öğesi
│   │       ├── message_bubble.dart        # Mesaj baloncuğu (gönderilen/alınan)
│   │       └── chat_input.dart            # Mesaj gönderme çubuğu
│   │
│   ├── notifications/
│   │   ├── screens/
│   │   │   └── notifications_screen.dart  # Bildirim listesi
│   │   └── widgets/
│   │       ├── notification_tile.dart     # Bildirim satır öğesi (6 tip)
│   │       └── notifications_app_bar.dart # Bildirimler AppBar (tümünü okundu işaretle)
│   │
│   ├── bookmarks/
│   │   └── screens/
│   │       └── bookmarks_screen.dart      # Kaydedilenler (swipe-to-dismiss, geri alma)
│   │
│   ├── settings/
│   │   ├── screens/
│   │   │   └── settings_screen.dart       # 5 bölümlü ayarlar (Görünüm, Dil, Bildirim, Hesap, Hakkında)
│   │   └── widgets/
│   │       ├── settings_section.dart      # Genişletilebilir bölüm container
│   │       └── settings_tile.dart         # Ayar satırı (chevron + toggle varyantları)
│   │
│   └── shell/
│       └── main_shell.dart                # Floating bottom nav bar (5 tab, glassmorphism)
│
└── shared/
    ├── extensions/
    │   ├── dental_branch_ui.dart          # DentalBranch → renk, ikon, Türkçe etiket
    │   ├── user_title_ui.dart             # UserTitle → Material ikonu
    │   ├── post_type_l10n.dart            # PostType → lokalize başlık ve emoji
    │   └── notification_type_l10n.dart    # NotificationType → lokalize bildirim metni
    └── widgets/
        ├── animated_action_button.dart    # Scale bounce + haptic feedback temel buton
        ├── like_button.dart               # Animasyonlu kalp butonu + sayaç
        ├── bookmark_button.dart           # Animasyonlu kaydet butonu
        ├── stat_count.dart                # Kompakt metrik gösterimi (ikon + sayı)
        ├── app_bottom_nav_bar.dart        # 5-tab floating nav bar (gradient "+" butonu)
        ├── branch_chip.dart               # Branş rozeti (branşa özel renk)
        ├── tag_chip.dart                  # Etiket chip'i
        ├── post_badge.dart                # Post tipi rozeti ("📸 Vaka" / "❓ Soru")
        ├── user_avatar.dart               # Cached network avatar (fallback initials)
        ├── user_tile.dart                 # Kullanıcı satır öğesi (avatar, isim, unvan)
        ├── relative_time_text.dart        # Lokalize göreli zaman ("5 dk önce")
        ├── post_header.dart               # Yazar avatar, isim, branş, zaman, seçenekler
        ├── post_media.dart                # Görsel carousel (çift tıklama kalp animasyonu)
        ├── post_action_bar.dart           # Beğeni + yorum + kaydet buton çubuğu
        ├── post_glass_container.dart      # Glassmorphism container (blur, border, shadow)
        ├── case_card.dart                 # Vaka kartı (görsel, etiket, aksiyon çubuğu)
        ├── question_card.dart             # Soru kartı (metin, etiket, aksiyon çubuğu)
        ├── post_card_factory.dart         # PostModel → CaseCard/QuestionCard factory
        ├── glass_field.dart               # Glassmorphism form alanı
        ├── glass_background_effect.dart   # Radial gradient glow arka plan efekti
        ├── loading_indicator.dart         # Spinner, shimmer card, loading overlay
        ├── empty_state.dart               # Boş durum widget'ı (ikon, başlık, alt metin)
        └── error_widget.dart              # Hata widget'ı (mesaj + yeniden dene butonu)
```

---

## 🔗 Bağımlılıklar (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Navigation
  go_router: ^14.8.1

  # Backend
  supabase_flutter: ^2.9.0

  # Localization
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

  # Image
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1

  # UI Utilities
  shimmer: ^3.0.0
  flutter_svg: ^2.0.17
  flutter_floating_bottom_bar: ^2.0.2

  # Persistence
  shared_preferences: ^2.5.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.15
```

### İleride Eklenecek Bağımlılıklar
```yaml
  # Faz 5 — Push Notifications
  firebase_messaging: ^15.x
  flutter_local_notifications: ^17.x
```

---

## 📐 Navigasyon Yapısı

### Kayıtlı Rotalar

| Rota | Ekran | Shell |
| --- | --- | --- |
| `/login` | `LoginScreen` | Hayır |
| `/register` | `RegisterScreen` | Hayır |
| `/feed` | `FeedScreen` | ✅ Bottom Nav |
| `/search` | `SearchScreen` | ✅ Bottom Nav |
| `/messages` | `ConversationsScreen` | ✅ Bottom Nav |
| `/profile` | `ProfileScreen` (mevcut kullanıcı) | ✅ Bottom Nav |
| `/feed/case/:id` | `CaseDetailScreen` | Hayır |
| `/feed/question/:id` | `QuestionDetailScreen` | Hayır |
| `/create-case` | `CreateCaseScreen` | Hayır |
| `/create-question` | `CreateQuestionScreen` | Hayır |
| `/chat/:userId` | `ChatScreen` | Hayır |
| `/profile/:userId` | `ProfileScreen` (başka kullanıcı) | Hayır |
| `/edit-profile` | `EditProfileScreen` | Hayır |
| `/network/:id` | `FollowersScreen` (`?tab=0`/`?tab=1`) | Hayır |
| `/notifications` | `NotificationsScreen` | Hayır |
| `/bookmarks` | `BookmarksScreen` | Hayır |
| `/settings` | `SettingsScreen` | Hayır |

### Ana Navigasyon (Bottom Navigation Bar — 5 Sekme)

1. **Ana Sayfa** (`/feed`) — Feed akışı
2. **Keşfet** (`/search`) — Arama ve filtreleme
3. **Oluştur (+)** — Modal bottom sheet açar: "Vaka Paylaş" (`/create-case`) veya "Soru Sor" (`/create-question`)
4. **Mesajlar** (`/messages`) — DM listesi
5. **Profil** (`/profile`) — Kullanıcı profili

### Ekran Akışı (Screen Flow)

```
Uygulama Başlatma
└── Auth Guard (GoRouter redirect)
    ├── Oturum yok → /login
    │   ├── OTP Doğrulama (login_screen.dart içinde)
    │   └── İlk kayıt → /register (3 adımlı sihirbaz)
    └── Oturum var → /feed
        └── Main Shell (Floating Bottom Nav Bar)
            ├── Feed Screen (/feed)
            │   ├── Case Detail (/feed/case/:id)
            │   │   └── Yorum Bölümü + Görsel Galerisi
            │   └── Question Detail (/feed/question/:id)
            │       └── Cevaplar + En İyi Cevap Seçimi
            ├── Search Screen (/search)
            │   └── Filtre Sonuçları (Gönderiler / Kullanıcılar)
            ├── Create (+) → Modal Sheet
            │   ├── Vaka Paylaş (/create-case)
            │   └── Soru Sor (/create-question)
            ├── Messages Screen (/messages)
            │   └── Chat Screen (/chat/:userId)
            └── Profile Screen (/profile)
                ├── Edit Profile (/edit-profile)
                ├── Followers/Following (/network/:id)
                ├── Bookmarks (/bookmarks)
                ├── Settings (/settings)
                │   ├── Tema Değiştirme
                │   ├── Dil Değiştirme
                │   ├── Bildirim Tercihleri
                │   └── Çıkış Yap
                └── Notifications (/notifications)
```

---

## 🎨 Tasarım Sistemi

### Renk Paleti
- **Primary:** Deep Teal `#0D9488` (Light) / Cyan Mint `#2DD4BF` (Dark)
- **Secondary:** Royal Violet `#7C3AED` (Light) / Lavender `#A78BFA` (Dark)
- **Surface:** Pure White `#FFFFFF` (Light) / Deep Charcoal `#0B0F17` (Dark)
- **Etkileşim:** Heart `#EF4444`, Bookmark `#F59E0B`, Success `#10B981`, Error `#EF4444`

### Glassmorphism
- `GlassThemeExtension` ile tokenize edilmiş blur sigma, surface tint opacity ve frost border renkleri
- `PostGlassContainer`, `GlassField`, `GlassBackgroundEffect` widget'ları ile uygulanır
- Hem aydınlık hem karanlık mod için optimize edilmiş parametreler

### Tipografi
- **Font Ailesi:** Plus Jakarta Sans
- **Ölçekler:** Display, Headline, Title, Body, Label (Material 3 type scale)

### Animasyonlar
- OTP kutularında shake, scatter ve merge animasyonları
- Post media'da çift tıklama kalp pop animasyonu
- Butonlarda 1.3x scale bounce + haptic feedback
- Feed AppBar'da floating pill dönüşüm animasyonu
- Bottom nav bar'da scroll-to-hide davranışı

---

## ⚠️ Açık Kararlar & Gelecek Tartışmalar

| Konu | Durum |
| --- | --- |
| Uygulama ismi (DentLink placeholder) | Karar verilecek |
| İş ilanları ve Malzeme alış/satış: akışta mı, ayrı sayfalarda mı? | Karar verilecek (Faz 6) |
| Rozet kuralları ve kriterleri | Detaylandırılacak (Faz 5) |
| Algoritmik feed detayları | Tasarlanacak (Faz 4) |
| Görsel sıkıştırma / boyut limiti | Belirlenecek (Faz 4) |
| Etiket öneri sistemi nasıl çalışacak? | Tasarlanacak (Faz 4) |
| İngilizce çeviriler eksik (~56 anahtar) | Tamamlanacak |
| Onboarding ekranı eklenecek mi? | Karar verilecek |
