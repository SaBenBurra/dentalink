# DentLink — Yol Haritası

> **Hedef:** Önce **sade bir MVP** ile mağazaya çık: vaka, soru, yorum, takip, DM, bildirim ve moderasyon. İş ilanları, pazar yeri, rozetler ve algoritmik feed yayından sonra gelir.
>
> **Kural:** Her madde [`AUDIT.md`](./AUDIT.md)'deki bir ID'ye bağlı. Bir maddeyi bitirince burada `[x]` yap, AUDIT'te durumu `✅` yap. Bir faz, **Bitti tanımı** sağlanmadan kapanmaz.
>
> **Yeni bir oturuma başlarken:** Bu dosyada ilk açık fazı bul ve oradan devam et.

---

## Geçmiş (özet)

| Faz | İçerik | Durum |
|---|---|---|
| 1 | Proje iskeleti: tema, l10n altyapısı, GoRouter, repository pattern | ✅ |
| 2 / 2.5 | Tüm ekranların mock veriyle UI demosu, navigasyon düzeltmeleri | ✅ |
| 3.1 | DB şeması, trigger'lar, RLS, indexler, `post-images` bucket'ı | ✅ (güvenlik açıkları Faz 0'da kapanıyor) |
| 3.2–3.6 | Gerçek Supabase: kullanıcı, post CRUD, yorum, takip, arama (Türkçe FTS) | ✅ |
| 3.7 | Mesajlaşma: repository, `get_or_create_conversation`, okundu RPC, realtime | ✅ (eksikler Faz 1'de) |
| 4.5 (kısmen) | `mark_best_answer` RPC | ✅ |
| Yeni Faz 0 | Stabilizasyon & güvenlik: migration 012, auth/state, kritik UI akışları, hijyen | ✅ (2026-10-15) |
| Faz 1 | Çekirdek akışlar: gerçek bildirimler, mesajlaşma, atomik post oluşturma/düzenleme, iyimser etkileşimler, migration 013–017, fake backend ile integration test + CI | ✅ (2026-10-25) |

---

## Faz 0 — Stabilizasyon & Güvenlik ✅

> Yeni özellik yok. Veri sızıntısını, veri kaybını ve kırık ana akışları kapat.

### 0.1 Veritabanı (`supabase/migrations/012_security_hardening.sql`)
- [x] Migration geçmişini onar: `supabase migration repair --status applied 001 … 011` — `DATA-1`
- [x] Like constraint'ini düzelt (partial unique index) — `DATA-2`
- [x] `users` için kolon bazlı GRANT ver; email/phone gizle ve trigger'la doldur — `SEC-1`, `SEC-6`, `SEC-12`
- [x] `posts` ve `comments` için kolon bazlı UPDATE — `SEC-4`, `SEC-5`
- [x] `messages` INSERT kontrolü ve yalnızca `deleted_at` güncellemesi — `SEC-2`, `SEC-8`
- [x] `conversations` INSERT/UPDATE revoke — `SEC-7`
- [x] `notifications` INSERT revoke — `SEC-3`
- [x] `tags` update policy'sini kaldır — `SEC-11`
- [x] `avatars` bucket'ı ve policy'leri — `SEC-10`
- [x] Realtime yayını — `DATA-11`
- [x] `increment_view_count` düzelt — `DATA-6`
- [x] Duplicate index ve ölü fonksiyonları kaldır — `DATA-14`, `DATA-15`

### 0.2 Auth & state
- [x] Profil yükleme hatası "profil yok" sayılmasın; router hata ekranı göstersin — `AUTH-1`
- [x] Çıkışta kullanıcıya özel provider'ları temizle — `AUTH-2`
- [x] Kayıt 0. adımda geri = çıkış — `AUTH-3`
- [x] Türkçe kullanıcı adı slug'ı + çakışmada yeniden deneme — `AUTH-4`
- [x] `created_at`/email/phone istemciden gönderilmesin; OTP normalize et; TLD regex'i — `AUTH-6`, `AUTH-7`
- [x] Badge `icon_name` — `DATA-3`
- [x] Mock bildirimleri kaldır (boş durum göster) — `DATA-5` (geçici)

### 0.3 Kritik UI akışları
- [x] Avatar ve kullanıcı satırlarından profile gitme — `BUG-1`, `BUG-20`
- [x] Profilde Takip et / Mesaj; detaydaki sahte takip butonunu düzelt — `BUG-2`, `BUG-8`
- [x] Post silme (yalnızca sahibine, onaylı); düzenle/raporla gizli — `BUG-3`, `DATA-7`
- [x] Oluşturma ve silme sonrası feed ve profili yenile — `BUG-4`
- [x] Profil sekmesinde like/bookmark; boş durum — `BUG-5`
- [x] Arama hata durumu, istek sırası, filtre temizleme — `BUG-6`, `BUG-14`
- [x] Bookmark kaydırma (önce yerelden çıkar, hata olursa geri al) — `BUG-7`
- [x] Sahte röntgen görselini kaldır; detail ekranlarında tip kontrolü ve AppBar — `BUG-9`, `BUG-10`
- [x] Ham hata metinlerini kaldır — `UX-3`
- [x] Avatar yükleme sırası — `DATA-8`

### 0.4 Yayın engeli & hijyen
- [x] iOS izin metinleri — `REL-1`
- [x] Kırık 3 testi düzelt; yeni testler: slug, redirect, sign-out — `TEST-1`, `TEST-3`
- [x] Ölü mock kodu, kökteki scriptler, build çıktısı — `HYG-1`, `HYG-2`, `HYG-3`
- [x] `supabase/config.toml` commit; pubspec temizliği — `HYG-4`, `HYG-5`

**Durum (2026-10-15):** Faz 0 kapandı. `flutter analyze` hatasız, `flutter test` 205/205, migration 001–012 local = remote, RLS smoke testleri 7/7 (2026-10-13), manuel duman testi cihazda geçti (2026-10-15).

**Bitti tanımı:**
- `flutter analyze` temiz, `flutter test` yeşil.
- `supabase migration list`'te local ve remote eşit.
- [`SUPABASE.md`](./SUPABASE.md)'deki RLS smoke testleri geçiyor.
- Hostta manuel duman testi tamam:
  1. Giriş yap → feed → başka bir kullanıcının profili → takip et → mesaj at.
  2. Vaka oluştur → feed'de gör → sil.
  3. Arama filtresini aç ve kapat; bookmark'ı kaydırarak sil.
  4. Çıkış yap → başka hesapla giriş yap → önceki kullanıcının verisi görünmüyor.

---

## Faz 1 — Çekirdek akışların tamamlanması ✅

- [x] **Bildirimler (gerçek):** migration 013 (like, yorum, takip, en iyi cevap trigger'ları; aktör = alıcı ise atlanır, okunmamış tekrar yazılmaz), realtime, zil ve mesaj rozetleri, iyimser okundu + rollback. Mesaj için ayrı bildirim yok, sohbet `unreadCount` yeterli. _(2026-10-15; iki hesapla cihazda doğrulandı 2026-10-20)_ — `DATA-5`, `UX-1`, `BUG-23`
- [x] **Mesajlaşma tamamlama:** migration 014 canlıda, smoke 9 geçti; doğrudan `messages` insert'ü kapalı. _(2026-10-20; cihazda anlık mesaj ve okunmamış rozeti doğrulandı)_
  - `send_message` RPC (get-or-create + insert tek işlemde, SEC-2'nin kalıcı çözümü), `nullsFirst:false` — `DATA-10`
  - Realtime'da append + filtre (`removeChannel` Faz 0'da yapıldı) — `BUG-18`
  - Sohbet ekranındaki ölü butonlar ve karşı kullanıcı bilgisi — `BUG-17`
- [x] **Atomik post oluşturma:** migration 015; `post_images.image_url` artık bucket içi yol, istemci `getPublicUrl` ile URL üretir. Önce görseller yüklenir, sonra `create_post` RPC; hata olursa dosyalar silinir. _(2026-10-20; canlıda, cihazda görselli vaka oluştur/sil ve silinmiş postu beğenme (BUG-27) doğrulandı)_ — `DATA-4`, `SEC-13`, `DATA-9`
- [x] **Post düzenleme ekranı** (başlık, içerik, branş, etiket) + menüde "Düzenle": migration 016 `update_post` RPC (sahiplik, doğrulama, etiket eşitleme); `posts` UPDATE yetkisi kaldırıldı. Görseller düzenlenmez. _(2026-10-20; canlıda, cihazda vaka ve soru düzenleme doğrulandı)_
- [x] **Avatar değiştirme** (edit profile): galeri/kamera, önizleme, kaydette yükleme; oturumsuz "başarılı" dönmüyor; deneyim 0–70 doğrulaması. _(2026-10-20; cihazda doğrulandı)_ — `BUG-16`
- [x] **İyimser like/bookmark**, in-flight guard, rollback; detaydan feed ve aramadaki tek öğe güncellenir (ortak `post_toggle.dart`); seri dokunuşta son dokunuş kazanır, 400 ms debounce ile tek istek. _(2026-10-21; cihazda doğrulandı 2026-10-25; debounce cihazda doğrulandı 2026-10-25)_ — `BUG-12`
- [x] **Çift gönderim korumaları** (yorum, cevap): gönderirken buton kilitli, `maxLength` 2000; yorum sayacı detay, feed ve aramada yeniden çekmeden +1. _(2026-10-25; testli, cihazda doğrulandı)_ — `BUG-13`
- [x] **Image picker** izin ve hata yönetimi: izin reddi ve picker hataları SnackBar ile anlatılır (vaka/soru ızgarası, kayıt avatarı), `limit:` ile seçim sınırlı, fazlası atılırsa uyarı. Ayarlara yönlendirme butonu yok (yeni paket gerekirdi), mesaj ayarları işaret eder. Android kamera ve galeri için sistem uygulamasını kullandığından izin istemez. _(2026-10-25; testli, Android cihazda limit doğrulandı)_ — `BUG-15`
- [x] **Etiket girişi:** `#` ve boşluk temizlenir, Türkçe küçültme, en fazla 5 etiket × 30 karakter, yapıştırılan metin bölünür; yazılmakta olan etiket de kaydedilir; `onTagTap` yokken etiket tıklanabilir görünmez. _(2026-10-25; testli, cihazda doğrulandı)_ — `BUG-25`
- [x] `mark_best_answer`: tip kontrolü, `unmark_best_answer` RPC + kartta "Seçimi Kaldır", en iyi cevap silinince `is_solved = false` (migration 017). _(2026-10-25; canlıda, smoke 12–13 geçti, cihazda doğrulanmadı)_ — `DATA-16`
- [x] Uzunluk CHECK'leri (migration 017): post başlığı 150, içerik 5000, yorum ve mesaj 2000, etiket 30 karakter, post başına 5 etiket (trigger); oluşturma ekranlarına `maxLength`; RPC `22023` → `ValidationFailure`. Profil alanları UX-8'de. _(2026-10-25; canlıda, smoke 13 geçti)_ — `DATA-17`
- [x] Paylaş butonu kaldırıldı — `BUG-11`
- [x] Ortak takipçiler: profili takip edenlerden benim takip ettiklerim (`mutualFollowersProvider`); kendi profilinde gizli. _(2026-10-25; testli, cihazda doğrulandı)_ — `BUG-19`
- [x] Bildirim ayarları toggle'ları kaldırıldı (DB tercihi ve push yok); tercihler Faz 5'te push ile gelir — `UX-4`
- [x] Integration test fake repository'lerle (`integration_test/fake_repositories.dart`); koşullu assertion yok; aynı akış headless `test/app_flow_test.dart` ile `flutter test`'te ve GitHub Actions CI'da (`.github/workflows/ci.yml`: analyze + test) koşar. _(2026-10-25; yerelde, Android emülatörde ve CI'da yeşil)_ — `TEST-2`

**Bitti tanımı:**
- İki gerçek hesapla: beğeni, yorum ve takip karşı tarafa bildirim olarak düşüyor; okunmamış rozeti artıp azalıyor.
- Mesaj anında geliyor.
- Post düzenlenebiliyor; görsel yüklemesi yarıda kesilince yarım post kalmıyor.
- Integration test CI'da yeşil.

**Durum (2026-10-25):** Faz 1 kapandı. `flutter analyze` hatasız, `flutter test` 233/233, migration 001–017 local = remote, smoke 12–13 geçti, integration test Android emülatörde ve GitHub Actions CI'da yeşil; bildirim, mesaj ve post düzenleme iki hesapla cihazda doğrulandı.

---

## Faz 2 — Ölçek & dayanıklılık 🟡

- [x] Cursor (keyset) sayfalama + sonsuz kaydırma: feed, yorumlar, arama, mesajlar, takipçiler, bookmark'lar. Liste sonundaki `LoadMoreFooter` göründükçe sonraki sayfayı ister (sohbette yukarı kaydırınca eski mesajlar); yorumlarda "Daha fazla göster" butonu. Silme ve profil etkileşimi yüklenen sayfaları korur (tek öğe güncellenir). Sohbet listesi sayfasız; ortak takipçiler hâlâ tam takipçi listesinden (DB kesişim RPC'si ayrı iş). _(2026-10-25; testli, cihazda doğrulanmadı)_ — `DATA-12`
- [ ] Görsel sıkıştırma (istemci tarafı) ve boyut limiti (ör. uzun kenar 2048px, ~1MB)
- [ ] `post-images` bucket'ını private yap + signed URL (KVKK) — `SEC-9`
- [ ] Tutarlı hata yönetimi: tüm repository'ler `guardSupabase` kullansın; `23505` ve `StorageException` eşlemesi
- [ ] Offline banner + yeniden deneme
- [ ] `onAuthStateChange` ile oturum düşmesini yakala — `AUTH-5`
- [ ] Sayaç CHECK'leri + uzlaştırma fonksiyonu — `DATA-18`
- [ ] `searchUsers` oturumsuz durumda çalışsın — `DATA-20`

**Bitti tanımı:** Seed ile 1.000+ post ve 200+ mesaj varken feed ve chat akıcı kayıyor; uçak modunda uygulama çökmüyor, anlamlı bir mesaj gösteriyor.

---

## Faz 3 — UX cilası & yerelleştirme 🟡

- [ ] Tüm sabit metinleri ARB'ye taşı (enum `displayName` dahil) — `UX-12`
- [ ] Boş, hata ve yenileme durumları her listede — `UX-7`
- [ ] `PopScope` (kaydedilmemiş form ve yükleme sırasında) — `UX-2`
- [ ] `maxLength`, `maxLines`, taşma düzeltmeleri, form doğrulamaları — `UX-8`, `UX-9`, `UX-10`
- [ ] Erişilebilirlik: tooltip/semantics, 48dp dokunma alanı, kontrast — `UX-13`, `UX-14`, `UX-15`
- [ ] Hardcoded renkleri temaya taşı — `UX-16`
- [ ] Tema tercihini kalıcı yap — `UX-11`
- [ ] Bookmarks ekranındaki tutarsızlıklar — `BUG-24`
- [ ] Kayıt başarı diyaloğu yarışı; hazır avatar kararı — `BUG-21`, `AUTH-8`
- [ ] Login küçük UX düzeltmeleri — `AUTH-10`
- [ ] Domain katmanı kararı (tamamla ya da kaldır) — `DATA-19`
- [ ] Ölü kod: ~~`FeedMode`~~ (DATA-12 ile kaldırıldı, `BUG-26` ✅); sohbet kullanıcı aramasında gerçek debounce — `BUG-22`

**Bitti tanımı:** Uygulama dili İngilizce'ye alınınca hiçbir Türkçe metin görünmüyor; en büyük yazı boyutunda ekranlar taşmıyor.

---

## Faz 4 — Moderasyon & hukuk 🛡️ (MVP için zorunlu)

- [ ] İçerik ve kullanıcı **raporlama** (`reports` tablosu + modal) — `UX-6`
- [ ] Kullanıcı **engelleme** (`blocks` tablosu + RLS ile içerik ve DM gizleme) — `UX-6`
- [ ] Moderasyon kuyruğu (başlangıçta Supabase Dashboard yeterli)
- [ ] **Hesap silme** (Edge Function: auth kullanıcısı + veriler + storage) — `UX-5`
- [ ] KVKK aydınlatma metni, gizlilik politikası, kullanım koşulları (uygulama içi + web)
- [ ] Hasta mahremiyeti uyarısı: vaka paylaşırken "yüz ve kimlik bilgisi içermediğini onaylıyorum" onay kutusu
- [ ] Kullanıcı doğrulama (diploma veya oda kaydı yükleme + admin onayı → `is_verified`)
- [ ] Ayarlar: sürüm bilgisi (`package_info_plus`), çıkış onayı — `UX-5`

**Bitti tanımı:** App Store ve Google Play inceleme gereksinimleri (UGC raporlama, engelleme, hesap silme, politika linkleri) karşılanıyor.

---

## Faz 5 — Yayın 🚀

- [ ] Uygulama adı, `applicationId`/bundle id, ikon, splash — `REL-4`, `UX-17`, `AUTH-11`
- [ ] Fontları bundle'a ekle — `REL-3`
- [ ] Android release imzalama (`key.properties`), R8 — `REL-2`
- [ ] iOS imzalama ve provisioning
- [ ] Production Supabase projesi + `--dart-define-from-file` (dev/prod) — `SEC-15`
- [ ] E-posta OTP şablonu ve SMTP; `site_url` — `AUTH-9`
- [ ] Crash raporlama (Sentry veya Crashlytics) — `REL-5`
- [ ] Push bildirim (FCM + `push_tokens` + Edge Function) + ayarlarda bildirim tercihleri (`notification_preferences`, UX-4) — `REL-6`
- [ ] Performans profili (başlatma süresi, jank, bellek)
- [ ] Beta testi (TestFlight + Play Internal) → mağaza açıklamaları ve ekran görüntüleri → yayın

---

## Yayın sonrası (backlog)

- Algoritmik feed (etkileşim skoru, `post_views`)
- Etiket önerisi ve otomatik tamamlama, etikete tıklayınca filtre
- Rozet ve başarım sistemi (`BadgeShowcase` zaten var)
- İş ilanları (`JobPostModel`), pazar yeri (`MarketplacePostModel`)
- Google ve Apple ile giriş (iOS'ta Google varsa Apple zorunlu)
- Deep link ile post/profil paylaşımı
- Onboarding slaytları
- Riverpod 3 ve go_router güncel major sürümlerine geçiş — `REL-7`

---

## Açık kararlar

| Konu | Ne zaman |
|---|---|
| Uygulama adı (DentLink placeholder) | Faz 5 öncesi |
| Kayıtta hazır avatar seçeneği kalsın mı? | Faz 3 |
| Domain katmanı: tamamla mı, kaldır mı? | Faz 3 |
| Görsel sıkıştırma limitleri | Faz 2 |
| Doğrulama belgesi türü (diploma / TDB oda kaydı) | Faz 4 |
| İş ilanı ve pazar yeri: feed'de mi, ayrı sekmede mi? | Yayın sonrası |
