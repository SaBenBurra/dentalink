# DentLink — Geliştirme Fazları & İlerleme

> **Strateji:** Önce tüm ekranların işlevsiz ama görsel olarak tamamlanmış bir demosunu oluştur (mock data ile). Somut arayüzü gördükten sonra geri bildirimle revize et, ardından backend'i bağla.

---

## Faz 1 — Proje İskeleti
- [x] Flutter projesi oluşturma
- [x] Tema sistemi (karanlık/aydınlık, SharedPreferences ile kalıcı)
- [x] Lokalizasyon altyapısı (TR + EN, ARB tabanlı ~179 çeviri, flutter gen-l10n)
- [x] Navigasyon yapısı (go_router + bottom nav shell + glassmorphism floating nav bar)
- [x] Mock data katmanı (5 mock datasource: vaka, soru, kullanıcı, bildirim, mesaj)
- [x] Paylaşılan temel widget'lar (11+ bileşen: avatar, badge chip, empty state, error widget, loading indicator, post card base, section header, shimmer list, stats item, tag chip, text field)
- [x] Veri modelleri (CasePost, QuestionPost, UserProfile, Badge, Answer, ChatMessage, Conversation, NotificationItem)

---

## Faz 2 — Arayüz Demosu (Mock Data ile)
Tüm ekranlar placeholder/mock verilerle görsel olarak tamamlanır. Hiçbir backend bağlantısı yoktur.

- [/] **Auth ekranları:**
  - [x] Login — Parolasız/OTP doğrulamalı (e-posta veya telefon → 6 haneli OTP). Glassmorphism arka plan, shake/scatter/merge animasyonları, geri sayım sayacı
  - [x] Register — 3 adımlı sihirbaz (1: Ad + Unvan kart ızgarası, 2: Mesleki bilgiler, 3: Profil fotoğrafı + biyografi). Animasyonlu ilerleme çubuğu, tamamlama diyalogu
  - [ ] Onboarding — Henüz uygulanmadı (kod tabanında dosyası yok)
- [x] **Feed ekranı:** 3 sekmeli filtreleme (Tümü / Vakalar / Sorular), vaka ve soru kartları (mock). Daralan/kayan AppBar (floating pill animasyonu), shimmer yükleme, pull-to-refresh
  - ⚠️ *Not: Provider'da kronolojik/algoritmik mod tanımlı ama UI'da henüz mod geçişi yok*
- [x] **Vaka detay ekranı:** PageView görsel galerisi (dot indicators), yazar bilgisi + takip butonu, yorum bölümü (yorum ekleme + yorum beğenme), beğeni/kaydetme butonları, etiketler
- [x] **Soru detay ekranı:** Cevap listesi, "En İyi Cevap" rozeti (yeşil çerçeve + onay ikonu), soru sahibine "En İyi Cevap Seç" butonu, cevap yazma alanı
- [x] **Post oluşturma ekranları:**
  - [x] Vaka oluştur — Başlık, açıklama, branş seçici (modal bottom sheet), etiket girişi (chip), görsel seçici (ImagePicker grid, maks 10). Form validasyonu mevcut
  - [x] Soru oluştur — Başlık, detay, etiket girişi, görsel seçici (opsiyonel, maks 4). Form validasyonu mevcut
  - ⚠️ *Not: Gönderim mantığı mock (1 sn gecikme). Faz 3'te backend'e bağlanacak*
- [x] **Profil ekranı:** NestedScrollView ile profil başlığı, avatar, biyografi, konum/üniversite, istatistikler (gönderi/takipçi/takip), sekmeli post listesi (Vakalar/Sorular), rozet vitrini (yatay kaydırılabilir). MutualFollowersWidget
  - ⚠️ *Not: Sadece mevcut kullanıcı profili görüntülenebilir. `/profile/:id` rotası (başka kullanıcı profili) henüz yok*
  - ⚠️ *Bug: ProfilePostsTab'da tıklanan postlar `/profile/case/:id` rotasına yönleniyor ama bu rota tanımlı değil (doğrusu `/feed/case/:id`)*
- [x] **Profil düzenleme ekranı:** Avatar değiştirme (placeholder), ad, unvan, branş, biyografi, üniversite, şehir, deneyim yılı, çalıştığı klinik. Mevcut verilerle ön doldurulmuş
  - ⚠️ *Not: Kaydetme mantığı mock. Avatar yükleme stub*
- [x] **Takipçiler/Takip edilenler ekranı:** 2 sekmeli (Takipçiler / Takip Edilenler), kullanıcı listesi
  - ⚠️ *Not: Takip et/bırak butonu UI'da var ama callback boş (çalışmıyor)*
- [x] **Keşfet/Arama ekranı:** Arama çubuğu (debounce), filtre chip'leri (İçerik Tipi + Branş), 2 sekmeli sonuç listesi (Gönderiler / Kullanıcılar). Boş durum ve popüler etiket gösterimi
  - ⚠️ *Not: onLikeToggle ve onBookmarkToggle callback'leri boş*
- [x] **Mesajlar ekranı:** Sohbet listesi (ConversationTile: avatar, isim, son mesaj, zaman, okunmamış sayısı), arama, boş durum
- [x] **Chat ekranı:** Mesaj baloncukları (gönderilen/alınan ayrımı, zaman damgası, görsel mesaj desteği), mesaj gönderme input alanı, eklenti butonu (placeholder)
  - ⚠️ *Not: Veriler hardcoded/in-memory. Repository tanımlı ama UI'a bağlı değil*
- [x] **Bildirimler ekranı:** Bildirim listesi (6 tip: beğeni, yorum, takip, mention, rozet, en iyi cevap), tümünü okundu işaretle, okunmamış göstergesi. Riverpod provider entegrasyonu tam
  - ⚠️ *Not: Bildirime tıklayınca ilgili gönderiye/profile yönlendirme henüz yok*
- [x] **Kaydedilenler ekranı:** Bookmark listesi (PostCardFactory ile), swipe-to-dismiss (onay diyalogu + geri alma SnackBar), pull-to-refresh, boş durum, hata durumu. bookmarkProvider entegrasyonu tam
  - ⚠️ *Not: onLikeToggle callback boş (feed ile senkronizasyon bekliyor)*
- [/] **Ayarlar ekranı:** 5 bölümlü (Görünüm, Dil, Bildirimler, Hesap, Hakkında)
  - [x] Tema değiştirme (Sistem/Aydınlık/Karanlık — modal bottom sheet, çalışıyor)
  - [x] Dil değiştirme (Türkçe/English — modal bottom sheet, çalışıyor)
  - [/] Bildirim tercihleri (4 toggle switch UI'da var ama callback'ler backend'e bağlı değil)
  - [x] Hesap: Profili Düzenle (yönlendirme çalışıyor)
  - [ ] Hesap: Gizlilik ve Engellenenler ("Yakında" etiketi ile devre dışı)
  - [ ] Hakkında: Kullanım Koşulları ve Gizlilik Politikası ("Yakında" etiketi ile devre dışı)
  - [x] Çıkış Yap (çalışıyor, auth state güncellenip /login'e yönlendiriyor)

> **Amaç:** Bu faz sonunda uygulamanın tüm ekranları arasında gezinilebilir, görsel olarak bitmiş bir demo elde edilir. Geri bildirim alınır, gerekirse revize edilir.

### Faz 2 — Bilinen Buglar & Eksikler
- 🐛 `ProfilePostsTab`: Post tıklaması `/profile/case/:id` → 404 hatası (doğru rota: `/feed/case/:id`)
- 🐛 `FollowersScreen`: Takip et/bırak butonu çalışmıyor (boş callback)
- ⚠️ Başka kullanıcı profili görüntüleme rotası (`/profile/:id`) mevcut değil
- ⚠️ Feed'de kronolojik/algoritmik mod geçişi UI'da yok (provider'da altyapı var)
- ⚠️ Bildirime tıklayınca deep-link navigasyon yok
- ⚠️ Mesajlaşma UI'ı repository'ye bağlı değil (hardcoded mock)

---

## Faz 3 — Backend Entegrasyonu
Mock data katmanı gerçek Supabase bağlantısıyla değiştirilir. Ekranlara dokunulmaz, sadece provider'lar güncellenir.

- [ ] Supabase proje kurulumu
- [ ] Veritabanı şeması oluşturma (tablolar, indeksler, RLS)
- [ ] Supabase Storage yapılandırması
- [ ] Kimlik doğrulama (e-posta, Google, telefon)
- [ ] Kullanıcı profili CRUD
- [ ] Vaka & soru CRUD
- [ ] Beğeni & yorum sistemi
- [ ] Takip sistemi
- [ ] Feed sorguları (kronolojik & algoritmik)
- [ ] Arama & filtreleme (full-text search)
- [ ] Kaydetme (bookmark)
- [ ] Mesajlaşma (Supabase Realtime)

---

## Faz 4 — Gelişmiş Özellikler
- [ ] Soru-cevap: "En İyi Cevap" seçimi
- [ ] Etiket sistemi (öneri mekanizması dahil)
- [ ] Görsel optimizasyonu (sıkıştırma, thumbnail, boyut limiti)
- [ ] Sayfalama (infinite scroll / cursor-based pagination)

---

## Faz 5 — Bildirim & Gamification
- [ ] Push bildirimler (FCM)
- [ ] Uygulama içi bildirimler
- [ ] Rozet & başarım sistemi

---

## Faz 6 — İleri Özellikler
- [ ] İş ilanları
- [ ] Kullanıcı raporlama & engelleme
- [ ] İçerik moderasyonu
- [ ] Kullanıcı doğrulama (diploma)
- [ ] Deep linking & paylaşım
- [ ] Analytics entegrasyonu
