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
├── created_at
└── updated_at

posts
├── id (UUID, PK)
├── user_id (FK → users)
├── type (enum: 'case', 'question')
├── title
├── content
├── branch (nullable, vaka için zorunlu)
├── is_solved (soru için, en iyi cevap seçildi mi)
├── created_at
└── updated_at

post_images
├── id (UUID, PK)
├── post_id (FK → posts)
├── image_url
├── order_index
└── created_at

tags
├── id (UUID, PK)
├── name (unique)
└── created_at

post_tags
├── post_id (FK → posts)
└── tag_id (FK → tags)

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
├── user_id (FK → users)
├── post_id (FK → posts, nullable)
├── comment_id (FK → comments, nullable)
└── created_at

follows
├── follower_id (FK → users)
├── following_id (FK → users)
└── created_at

bookmarks
├── user_id (FK → users)
├── post_id (FK → posts)
└── created_at

messages
├── id (UUID, PK)
├── sender_id (FK → users)
├── receiver_id (FK → users)
├── content
├── is_read
└── created_at

conversations
├── id (UUID, PK)
├── user1_id (FK → users)
├── user2_id (FK → users)
├── last_message_id (FK → messages)
└── updated_at

notifications
├── id (UUID, PK)
├── user_id (FK → users)
├── type (enum: 'like', 'comment', 'follow', 'message')
├── actor_id (FK → users)
├── post_id (FK → posts, nullable)
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
├── user_id (FK → users)
├── badge_id (FK → badges)
└── earned_at
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
