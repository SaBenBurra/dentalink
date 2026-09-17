# DentLink — Geliştirme Yol Haritası & İlerleme

> **Strateji:** Önce tüm ekranların işlevsiz ama görsel olarak tamamlanmış demosunu oluştur (mock data ile). Somut arayüzü gördükten sonra geri bildirimle revize et, ardından backend'i bağla.

> **📌 İlgili Dosya:** Proje spesifikasyonu ve mimari kararlar için [`agents.md`](./agents.md) dosyasını oku.

---

## Mevcut Durum Özeti

| Katman | Durum |
| --- | --- |
| **Flutter İskeleti** | ✅ Tamamlandı — 136 Dart dosyası, feature-driven mimari |
| **Tema & Lokalizasyon** | ✅ Çalışıyor — Light/Dark mod, TR çevirileri tam (~93 anahtar), EN eksik (~56 anahtar) |
| **Navigasyon** | ✅ Çalışıyor — GoRouter + Auth guard + Bottom nav shell |
| **Mock Data Katmanı** | ✅ Çalışıyor — 6 mock repository + merkezi MockDatasource |
| **Supabase Auth** | ✅ Gerçek bağlantı — OTP (e-posta/SMS) + profil kayıt + avatar yükleme |
| **Supabase Database** | ⏳ Henüz başlanmadı — Sadece `users` tablosu var (auth akışı için) |
| **Diğer Repository'ler** | ⏳ Tamamı mock — Post, Comment, Message, Notification, User |

---

## Faz 1 — Proje İskeleti ✅

- [x] Flutter projesi oluşturma (SDK ^3.12.2)
- [x] Tema sistemi (karanlık/aydınlık, SharedPreferences ile kalıcı)
- [x] Glassmorphism tasarım tokenleri (`GlassThemeExtension`)
- [x] Tipografi sistemi (Plus Jakarta Sans, Material 3 type scale)
- [x] Renk paleti (Deep Teal / Cyan Mint, Royal Violet / Lavender)
- [x] Spacing & boyut sabitleri (`AppDimensions`)
- [x] Lokalizasyon altyapısı (TR + EN, ARB tabanlı, `flutter gen-l10n`)
- [x] Navigasyon yapısı (GoRouter + ShellRoute + floating bottom nav bar)
- [x] Auth guard (oturum kontrolü + profil kontrolü + redirect logic)
- [x] Mock data katmanı (merkezi `MockDatasource` — 1182 satır)
- [x] Repository pattern (abstract interface + mock implementation + Riverpod DI)
- [x] Paylaşılan widget kütüphanesi (25+ widget: avatar, badge, card, glass container vb.)
- [x] Veri modelleri (sealed `PostModel`, `UserModel`, `CommentModel`, `ConversationModel`, `MessageModel`, `NotificationModel`, `BadgeModel`, `TagModel`)
- [x] Enum tanımları (`UserTitle`, `DentalBranch`, `PostType`, `NotificationType`)
- [x] Extension'lar (DentalBranch UI, UserTitle UI, PostType l10n, NotificationType l10n)

---

## Faz 2 — Arayüz Demosu (Mock Data ile)

Tüm ekranlar mock verilerle görsel olarak tamamlanır. Backend bağlantısı yalnızca Auth modülünde aktiftir.

### ✅ Tamamlanan Ekranlar

- [x] **Login ekranı** — Parolasız OTP doğrulama (e-posta veya telefon → 6 haneli OTP). Glassmorphism arka plan, shake/scatter/merge animasyonları, geri sayım, rate limiter. **Gerçek Supabase Auth bağlantısı aktif.**
- [x] **Register ekranı** — 3 adımlı sihirbaz (Ad+Unvan → Mesleki bilgiler → Profil fotoğrafı+Biyografi). Animasyonlu ilerleme çubuğu, tamamlama diyalogu. **Gerçek Supabase profil kaydı + avatar yükleme aktif.**
- [x] **Feed ekranı** — 3 sekmeli filtreleme (Tümü / Vakalar / Sorular). Daralan/kayan AppBar (floating pill), shimmer yükleme, pull-to-refresh. PostCardFactory ile kart render.
- [x] **Vaka detay ekranı** — PageView görsel galerisi, yazar bilgisi + takip butonu, yorum bölümü, beğeni/kaydetme, etiketler.
- [x] **Soru detay ekranı** — Cevap listesi, "En İyi Cevap" rozeti (yeşil çerçeve + onay), soru sahibine "En İyi Cevap Seç" butonu.
- [x] **Vaka oluştur** — Başlık, açıklama, branş seçici (modal bottom sheet), etiket girişi (chip), görsel seçici (maks 10). Form validasyonu mevcut.
- [x] **Soru oluştur** — Başlık, detay, etiket, görsel seçici (opsiyonel, maks 4). Form validasyonu mevcut.
- [x] **Profil ekranı** — NestedScrollView, avatar, biyografi, konum/üniversite, istatistikler, sekmeli post listesi, rozet vitrini, MutualFollowersWidget.
- [x] **Profil düzenleme** — Avatar değiştirme, ad, unvan, biyografi, üniversite, şehir, deneyim yılı, klinik. Ön doldurulmuş form.
- [x] **Takipçiler ekranı** — 2 sekmeli (Takipçiler / Takip Edilenler), kullanıcı listesi.
- [x] **Keşfet/Arama** — Arama çubuğu (debounce 500ms), filtre chip'leri (İçerik Tipi + Branş), 2 sekmeli sonuç (Gönderiler / Kullanıcılar).
- [x] **Mesajlar listesi** — ConversationTile: avatar, isim, son mesaj, zaman, okunmamış sayısı, arama.
- [x] **Chat ekranı** — Mesaj baloncukları (gönderilen/alınan), zaman damgası, görsel mesaj, gönderme input'u.
- [x] **Bildirimler** — 6 tip bildirim listesi, tümünü okundu işaretle, okunmamış göstergesi. Provider entegrasyonu tam.
- [x] **Kaydedilenler** — Bookmark listesi, swipe-to-dismiss, geri alma SnackBar, pull-to-refresh, boş/hata durumu.
- [x] **Ayarlar** — Tema değiştirme ✅, Dil değiştirme ✅, Çıkış yap ✅, Profili düzenle yönlendirmesi ✅.

### 🐛 Faz 2 — Bilinen Buglar & Eksikler

| # | Tür | Açıklama | Konum |
|---|------|----------|-------|
| B1 | 🐛 Bug | `ProfilePostsTab`: Post tıklaması `/profile/case/:id` rotasına yönleniyor → 404 hatası. Doğru rota: `/feed/case/:id` | [profile_posts_tab.dart](file:///home/user/Projects/dentlink/lib/features/profile/widgets/profile_posts_tab.dart#L34) |
| B2 | 🐛 Bug | `FollowersScreen`: Takip et/bırak butonu callback'i boş — butona basınca hiçbir şey olmuyor | followers_screen.dart |
| E1 | ⚠️ Eksik | Başka kullanıcı profili görüntüleme (`/profile/:id`) rotası `app_router.dart`'ta tanımlı değil | [app_router.dart](file:///home/user/Projects/dentlink/lib/core/router/app_router.dart) |
| E2 | ⚠️ Eksik | Feed'de kronolojik/algoritmik mod geçişi UI'da yok (provider altyapısı var) | feed_screen.dart |
| E3 | ⚠️ Eksik | Bildirime tıklanınca ilgili gönderi/profile deep-link navigasyon yok | notifications_screen.dart |
| E4 | ⚠️ Eksik | Mesajlaşma UI'ı repository'ye bağlı değil (hardcoded in-memory veri) | chat_screen.dart |
| E5 | ⚠️ Eksik | Post oluşturma gönderim mantığı mock (1 sn gecikme, backend'e gitmiyor) | [create_case_controller.dart](file:///home/user/Projects/dentlink/lib/features/post/providers/create_case_controller.dart#L27) |
| E6 | ⚠️ Eksik | Profil düzenleme kaydetme mantığı mock | [edit_profile_controller.dart](file:///home/user/Projects/dentlink/lib/features/profile/providers/edit_profile_controller.dart#L32) |
| E7 | ⚠️ Eksik | Post header'da seçenekler menüsü (düzenle/sil/raporla) eklenmemiş | [post_header.dart](file:///home/user/Projects/dentlink/lib/shared/widgets/post_header.dart#L94) |
| E8 | ⚠️ Eksik | Bildirim tercihleri toggle'ları backend'e bağlı değil | settings_screen.dart |
| E9 | ⚠️ Eksik | Onboarding ekranı (ilk açılış tanıtım) — dosyası hiç yok | — |
| E10 | ⚠️ Eksik | İngilizce çeviriler eksik (~56 anahtar `intl_en.arb`'de yok) | intl_en.arb |

---

## Faz 2.5 — Bug Düzeltmeleri & UI Tamamlama 🔧

> **Amaç:** Backend entegrasyonuna geçmeden önce tüm UI akışlarının sorunsuz çalıştığından emin ol. Eksik rotaları, boş callback'leri ve kırık navigasyonları düzelt.

- [x] **B1 düzelt:** `ProfilePostsTab`'da rota `/feed/case/:id` ve `/feed/question/:id` olarak düzelt
- [x] **E1 düzelt:** `/profile/:id` rotasını `app_router.dart`'a ekle (başka kullanıcı profil görüntüleme)
- [x] **B2 düzelt:** `FollowersScreen` takip et/bırak butonunu provider'a bağla (mock seviyesinde çalışır hale getir)
- [x] **E3 düzelt:** Bildirime tıklanınca ilgili gönderi/profil sayfasına yönlendirme ekle
- [x] **E4 düzelt:** Chat ekranını `MessageRepository` provider'ına bağla (mock veriyle çalışır hale getir)
- [x] **E7 düzelt:** Post header'a seçenekler menüsü ekle (düzenle/sil/raporla — şimdilik sadece UI)
- [x] **E10 tamamla:** Eksik İngilizce çevirileri (`intl_en.arb`) tamamla
- [ ] **UI geçişi:** Tüm ekranlar arası navigasyonları uçtan uca test et, kırık akış kalmamalı

> **Çıktı:** Uygulamanın tüm ekranları arasında sorunsuz gezinilebilen, tüm butonları çalışan (mock seviyesinde) bir demo. Geri bildirim alınır, gerekirse revize edilir.

---

## Faz 3 — Supabase Veritabanı & Çekirdek Backend Entegrasyonu 🗄️

> **Amaç:** Mock data katmanını gerçek Supabase bağlantısıyla değiştir. UI koduna dokunulmaz, sadece repository implementasyonları ve provider'lar güncellenir.
>
> **Önkoşul:** Faz 2.5 tamamlanmış olmalı.

### 3.1 — Veritabanı Altyapısı
- [ ] Supabase Dashboard'da veritabanı şemasını oluştur (SQL migration):
  - [ ] PostgreSQL ENUM tipleri (`dental_branch`, `notification_type`)
  - [ ] `users` tablosu (mevcut, kontrol et + eksik sütunları ekle)
  - [ ] `posts` tablosu + `post_images` tablosu
  - [ ] `tags` + `post_tags` (many-to-many)
  - [ ] `comments` tablosu
  - [ ] `likes` tablosu (polimorfik: post_id XOR comment_id)
  - [ ] `follows` tablosu
  - [ ] `bookmarks` tablosu
  - [ ] `conversations` + `messages` tabloları
  - [ ] `notifications` tablosu
- [ ] Gerekli indeksleri oluştur (foreign key'ler, composite index'ler, full-text search)
- [ ] Denormalize sayaç trigger'larını yaz (`like_count`, `comment_count`, `bookmark_count`, `followers_count` vb.)
- [ ] Row Level Security (RLS) politikalarını tanımla:
  - [ ] `users`: Herkes okuyabilir, sadece kendi profilini güncelleyebilir
  - [ ] `posts`: Herkes okuyabilir, sadece kendi postunu oluşturabilir/güncelleyebilir/silebilir
  - [ ] `comments`: Herkes okuyabilir, kendi yorumunu yönetebilir
  - [ ] `likes` / `bookmarks` / `follows`: Kendi kayıtlarını yönetebilir
  - [ ] `messages`: Sadece gönderen veya alıcı okuyabilir/yazabilir
  - [ ] `notifications`: Sadece hedef kullanıcı okuyabilir
- [ ] Supabase Storage bucket'larını yapılandır:
  - [ ] `avatars` bucket (mevcut, kontrol et)
  - [ ] `post-images` bucket (yeni)

### 3.2 — Kullanıcı Profili (SupabaseUserRepository)
- [ ] `SupabaseUserRepository` oluştur (`UserRepository` abstract interface'ini implemente et)
- [ ] Profil getirme (`getUserById`, `getUsersByIds`)
- [ ] Profil güncelleme (`updateProfile`) — `EditProfileController`'ı bağla
- [ ] Avatar yükleme/güncelleme (Storage entegrasyonu)
- [ ] `repository_providers.dart`'ta `MockUserRepository` → `SupabaseUserRepository` geçişi

### 3.3 — Post CRUD (SupabasePostRepository)
- [ ] `SupabasePostRepository` oluştur (`PostRepository` interface'ini — `IFeedRepository`, `ISearchRepository`, `IBookmarkRepository`, `IPostActionRepository` — implemente et)
- [ ] Vaka oluşturma (post + post_images + post_tags insert) — `CreateCaseController`'ı bağla
- [ ] Soru oluşturma (post + post_tags insert) — `CreateQuestionController`'ı bağla
- [ ] Post silme (soft delete veya cascade)
- [ ] Feed sorgusu (kronolojik sıralama, posts + user join + images)
- [ ] Post detay getirme (tek post + yorumlar + yazar bilgisi)
- [ ] Beğeni toggle (insert/delete + sayaç trigger)
- [ ] Bookmark toggle (insert/delete)
- [ ] `repository_providers.dart`'ta `MockPostRepository` → `SupabasePostRepository` geçişi

### 3.4 — Yorum Sistemi (SupabaseCommentRepository)
- [ ] `SupabaseCommentRepository` oluştur
- [ ] Yorum ekleme / silme
- [ ] Yorum beğeni toggle
- [ ] Post'a ait yorumları getirme (kullanıcı bilgisiyle birlikte)
- [ ] `repository_providers.dart`'ta geçiş

### 3.5 — Takip Sistemi
- [ ] `follows` tablosu CRUD (follow/unfollow)
- [ ] Takipçi/takip edilen listesi getirme
- [ ] Sayaç trigger'ları (`followers_count`, `following_count`)
- [ ] `UserRepository`'ye takip metodlarını ekle veya ayrı `FollowRepository` oluştur

### 3.6 — Arama & Filtreleme
- [ ] PostgreSQL full-text search konfigürasyonu (Türkçe dil desteği ile `tsvector`)
- [ ] Post arama (başlık + içerik)
- [ ] Kullanıcı arama (isim + unvan + üniversite)
- [ ] Branş ve içerik türü filtreleme
- [ ] `SearchNotifier`'ı gerçek repository'ye bağla

### 3.7 — Mesajlaşma (SupabaseMessageRepository + Realtime)
- [ ] `SupabaseMessageRepository` oluştur
- [ ] Conversation CRUD (var olan sohbeti bul veya yeni oluştur)
- [ ] Mesaj gönderme / silme (soft delete)
- [ ] Mesaj geçmişi getirme (sayfalı)
- [ ] Supabase Realtime subscription (yeni mesaj dinleme)
- [ ] Okundu durumu güncelleme (`is_read`, `unread_count`)
- [ ] `last_message_preview` otomatik güncelleme (trigger veya uygulama tarafı)
- [ ] `repository_providers.dart`'ta geçiş

> **Çıktı:** Tüm temel CRUD işlemleri gerçek Supabase'e bağlı. Uygulama gerçek veriyle çalışıyor. Mesajlaşma real-time.

---

## Faz 4 — Performans, Kalite & Gelişmiş Özellikler ⚡

> **Amaç:** Uygulamayı production-ready kaliteye getir. Veri büyüdükçe ölçeklenecek teknik altyapıyı kur.
>
> **Önkoşul:** Faz 3 tamamlanmış olmalı.

### 4.1 — Sayfalama & Sonsuz Kaydırma
- [ ] Feed'de cursor-based pagination (created_at + id ile)
- [ ] Yorum listesinde sayfalama
- [ ] Arama sonuçlarında sayfalama
- [ ] Mesaj geçmişinde sayfalama (yukarı kaydırınca eski mesajlar)
- [ ] Takipçi/takip edilen listesinde sayfalama

### 4.2 — Görsel Optimizasyonu
- [ ] Yükleme öncesi istemci tarafı görsel sıkıştırma (boyut + kalite)
- [ ] Dosya boyutu limiti belirleme ve uygulama (ör: maks 5MB/görsel)
- [ ] Supabase Storage transform ile thumbnail oluşturma (listeleme için küçük boyut)
- [ ] Progresif görsel yükleme (blur placeholder → full image)

### 4.3 — Etiket Sistemi Geliştirmesi
- [ ] Popüler etiket önerisi (usage_count'a göre sıralı)
- [ ] Etiket otomatik tamamlama (yazarken öneri)
- [ ] Etiket bazlı gönderi keşfetme (etikete tıklayınca o etiketle filtrelenmiş sonuçlar)

### 4.4 — Feed İyileştirmeleri
- [ ] Kronolojik / Algoritmik mod geçiş UI'ı feed'e ekle
- [ ] Algoritmik feed sıralama mantığı tasarla ve uygula (engagement skoru: like + comment + view ağırlıklı)
- [ ] `post_views` tablosu ile görüntülenme takibi
- [ ] Feed cache stratejisi (stale-while-revalidate pattern)

### 4.5 — Soru-Cevap İyileştirmeleri
- [ ] "En İyi Cevap" seçimi backend entegrasyonu (comments.is_best_answer + posts.is_solved güncelleme)
- [ ] En iyi cevap seçildikten sonra bildirim gönderme altyapısı
- [ ] Soru "Çözüldü" durumu gösterimi

### 4.6 — Hata Yönetimi & UX
- [ ] Tüm repository çağrılarına tutarlı hata yakalama ve kullanıcı dostu mesajlar ekle
- [ ] Ağ bağlantısı yokken graceful degradation (offline banner, retry mekanizması)
- [ ] Optimistik güncelleme tutarlılığı (beğeni, bookmark, takip için rollback senaryoları)

> **Çıktı:** Uygulama büyük veri setleriyle sorunsuz çalışıyor. Görsel yükleme hızlı. Feed akıllı. Etiketler kullanışlı.

---

## Faz 5 — Bildirimler & Gamification 🔔🏅

> **Amaç:** Push bildirimler ve rozet sistemiyle kullanıcı bağlılığını artır.
>
> **Önkoşul:** Faz 4 tamamlanmış olmalı (özellikle "En İyi Cevap" backend'i).

### 5.1 — Uygulama İçi Bildirimler (Supabase)
- [ ] `SupabaseNotificationRepository` oluştur
- [ ] Bildirim oluşturma trigger'ları (beğeni, yorum, takip, en iyi cevap → `notifications` tablosu insert)
- [ ] Bildirim listesi getirme (sayfalı, kullanıcı bilgisiyle)
- [ ] Okundu işaretleme / tümünü okundu işaretleme
- [ ] Bildirime tıklayınca ilgili sayfaya deep-link navigasyon
- [ ] Supabase Realtime ile yeni bildirim dinleme (unread badge güncelleme)
- [ ] `repository_providers.dart`'ta geçiş

### 5.2 — Push Bildirimler (FCM)
- [ ] `firebase_messaging` ve `flutter_local_notifications` bağımlılıklarını ekle
- [ ] Firebase proje kurulumu (Android + iOS yapılandırma dosyaları)
- [ ] `push_tokens` tablosu CRUD (cihaz token kaydı, platform bilgisi)
- [ ] Supabase Edge Function: bildirim oluşturulduğunda FCM push gönderme
- [ ] Bildirim tercihleri backend bağlantısı (`notification_preferences` JSONB alan)
- [ ] Arka planda ve ön planda bildirim gösterimi
- [ ] Bildirime tıklayınca uygulama içi yönlendirme

### 5.3 — Rozet & Başarım Sistemi
- [ ] `badges` tablosuna başlangıç rozetlerini seed et (Yeni Üye, Uzman, Popüler, Yardımsever)
- [ ] Rozet kazanma kriterlerini tanımla (JSON criteria formatı):
  - Yeni Üye: Kayıt olduğunda otomatik
  - Uzman: Belirli branşta X vaka paylaşımı
  - Popüler: Toplam Y beğeni
  - Yardımsever: Z tane "En İyi Cevap" seçilmesi
- [ ] Supabase Edge Function veya pg_cron ile periyodik rozet hesaplama
- [ ] Rozet kazanıldığında bildirim oluşturma
- [ ] `BadgeShowcase` widget'ını gerçek veriye bağla
- [ ] Profilde rozet detayı görüntüleme (kazanılma tarihi, kriter bilgisi)

> **Çıktı:** Kullanıcılar etkileşimlerden push bildirim alıyor. Rozet sistemi motivasyon sağlıyor.

---

## Faz 6 — Güvenlik, Moderasyon & Yeni İçerik Türleri 🛡️

> **Amaç:** Platform güvenliğini sağla ve içerik çeşitliliğini artır.
>
> **Önkoşul:** Faz 5 tamamlanmış olmalı.

### 6.1 — Kullanıcı Güvenliği
- [ ] Kullanıcı engelleme (`blocks` tablosu, RLS ile engellenen kişinin içeriğini gizleme)
- [ ] İçerik/kullanıcı raporlama (`reports` tablosu, raporlama modal'ı)
- [ ] Post seçenekler menüsüne "Raporla" ve "Engelle" seçeneklerini bağla

### 6.2 — İçerik Moderasyonu
- [ ] Raporlanan içerikleri yönetme arayüzü (admin panel veya Supabase Dashboard üzerinden)
- [ ] Otomatik spam/uygunsuz içerik filtresi (opsiyonel, Edge Function)
- [ ] Moderasyon politikaları ve kurallar sayfası

### 6.3 — Kullanıcı Doğrulama
- [ ] Diploma/belge yükleme akışı (Storage'a yükleme)
- [ ] Doğrulama durumu gösterimi (onaylı kullanıcı rozeti ✓)
- [ ] Manuel doğrulama süreci (admin onayı)

### 6.4 — Yeni İçerik Türleri
- [ ] **İş İlanları (Job Posts):** `PostModel` sealed class'ına `JobPostModel` varyantı ekle
  - [ ] İlan oluşturma ekranı (başlık, açıklama, şehir, kurum)
  - [ ] İlan kartı widget'ı + PostCardFactory'ye entegre
  - [ ] Feed'e iş ilanı filtre sekmesi ekle
- [ ] **Malzeme Alış/Satışı (Marketplace Posts):** `MarketplacePostModel` varyantı ekle
  - [ ] Pazar yeri oluşturma ekranı (başlık, açıklama, fiyat, görseller)
  - [ ] Pazar yeri kartı widget'ı
  - [ ] Ayrı sayfa mı yoksa feed içinde mi? → Karar verilecek

### 6.5 — Ek Özellikler
- [ ] Deep linking & paylaşım (post/profil URL'si oluşturma ve paylaşma)
- [ ] Onboarding ekranları (ilk açılış tanıtım slaytları)
- [ ] Gizlilik politikası ve kullanım koşulları sayfaları
- [ ] Analytics entegrasyonu (Firebase Analytics veya Supabase Analytics)
- [ ] Google Sign-In entegrasyonu (Supabase Auth ile)

> **Çıktı:** Platform güvenli, moderasyonlu, çeşitli içerik türleriyle zenginleştirilmiş halde.

---

## Faz 7 — Yayına Hazırlık & Lansman 🚀

> **Amaç:** Uygulamayı mağazalara yüklemeye hazırla.
>
> **Önkoşul:** Faz 6'nın kritik kısımları (6.1, 6.2) tamamlanmış olmalı.

- [ ] Uygulama ismi kesinleştir (DentLink placeholder)
- [ ] Uygulama ikonu ve splash screen tasarımı
- [ ] Mağaza açıklamaları ve ekran görüntüleri hazırla
- [ ] Android release build yapılandırması (signing, ProGuard)
- [ ] iOS release build yapılandırması (certificates, provisioning)
- [ ] Performance profiling ve optimizasyon (jank, bellek, başlatma süresi)
- [ ] Supabase production ortamı kurulumu (ayrı proje, environment variables)
- [ ] Güvenlik denetimi (API anahtarları .env'e taşıma, RLS son kontrol)
- [ ] Hata takibi entegrasyonu (Sentry veya Firebase Crashlytics)
- [ ] Beta test (TestFlight + Google Play Internal Testing)
- [ ] Google Play Store ve App Store'a yükleme

---

## ⚠️ Açık Kararlar & Gelecek Tartışmalar

| Konu | İlgili Faz | Durum |
| --- | --- | --- |
| Uygulama ismi (DentLink placeholder) | Faz 7 | Karar verilecek |
| Onboarding ekranı eklenecek mi? | Faz 6.5 | Karar verilecek |
| İş ilanları ve Marketplace: feed içinde mi, ayrı sayfalarda mı? | Faz 6.4 | Karar verilecek |
| Rozet kuralları ve kriterleri (eşik değerler) | Faz 5.3 | Detaylandırılacak |
| Algoritmik feed formülü | Faz 4.4 | Tasarlanacak |
| Görsel sıkıştırma kalite/boyut limitleri | Faz 4.2 | Belirlenecek |
| Etiket öneri sistemi nasıl çalışacak? | Faz 4.3 | Tasarlanacak |
| Türkçe full-text search konfigürasyonu | Faz 3.6 | Araştırılacak |
| `main.dart`'taki Supabase anahtarları .env'e taşınmalı | Faz 7 | Yapılacak |
