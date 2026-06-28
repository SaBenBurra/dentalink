# DentLink — Geliştirme Fazları & İlerleme

> **Strateji:** Önce tüm ekranların işlevsiz ama görsel olarak tamamlanmış bir demosunu oluştur (mock data ile). Somut arayüzü gördükten sonra geri bildirimle revize et, ardından backend'i bağla.

---

## Faz 1 — Proje İskeleti
- [x] Flutter projesi oluşturma
- [x] Tema sistemi (karanlık/aydınlık)
- [x] Lokalizasyon altyapısı (TR + EN, ARB tabanlı, flutter gen-l10n)
- [x] Navigasyon yapısı (go_router + bottom nav shell)
- [x] Mock data katmanı (provider'lar mock veri döndürecek şekilde)
- [x] Paylaşılan temel widget'lar (avatar, loading, empty state, hata widget'ı + 5 ek ortak bileşen)

---

## Faz 2 — Arayüz Demosu (Mock Data ile)
Tüm ekranlar placeholder/mock verilerle görsel olarak tamamlanır. Hiçbir backend bağlantısı yoktur.

- [/] **Auth ekranları:** Login (şifresiz/doğrulama kodlu tamamlandı), Register (çok adımlı tamamlandı), Unvan Seçimi (kart gridli tamamlandı), Onboarding (beklemede)
- [x] **Feed ekranı:** Kronolojik/algoritmik tab'lar, vaka kartları, soru kartları (mock)
- [x] **Vaka detay ekranı:** Görsel galerisi, yorum bölümü, beğeni/kaydetme butonları
- [x] **Soru detay ekranı:** Cevaplar, "En İyi Cevap" rozeti
- [x] **Post oluşturma ekranları:** Vaka oluştur, soru oluştur (form arayüzleri)
- [x] **Profil ekranı:** Profil başlığı, istatistikler, sekmeli post listesi, rozet vitrin
- [x] **Profil düzenleme ekranı**
- [x] **Takipçiler/Takip edilenler ekranı**
- [ ] **Keşfet/Arama ekranı:** Arama çubuğu, filtre chip'leri, sonuç listesi
- [ ] **Mesajlar ekranı:** Sohbet listesi
- [ ] **Chat ekranı:** Mesaj baloncukları, input alanı
- [ ] **Bildirimler ekranı:** Bildirim listesi
- [ ] **Kaydedilenler ekranı:** Bookmark listesi
- [ ] **Ayarlar ekranı:** Tema, dil, bildirim tercihleri

> **Amaç:** Bu faz sonunda uygulamanın tüm ekranları arasında gezinilebilir, görsel olarak bitmiş bir demo elde edilir. Geri bildirim alınır, gerekirse revize edilir.

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
