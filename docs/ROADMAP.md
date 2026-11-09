# Dentigo — Yol Haritası

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
| Faz 2 | Ölçek & dayanıklılık: keyset sayfalama, görsel sıkıştırma, private `post-images`, tutarlı hata eşleme, offline banner, oturum düşmesi, sayaç uzlaştırma, migration 018–021, yük testi | ✅ (2026-10-25) |
| Faz 3 | UX cilası: ARB'ye taşıma (TR+EN), boş/hata/yenileme durumları, PopScope, uzunluk sınırları (022), erişilebilirlik, tema renkleri, etiket önerisi (025) | ✅ (2026-10-25) |

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
- [x] `mark_best_answer`: tip kontrolü, `unmark_best_answer` RPC + kartta "Seçimi Kaldır", en iyi cevap silinince `is_solved = false` (migration 017). _(2026-10-25; canlıda, smoke 12–13 geçti, cihazda doğrulandı 2026-10-25)_ — `DATA-16`
- [x] Uzunluk CHECK'leri (migration 017): post başlığı 150, içerik 5000, yorum ve mesaj 2000, etiket 30 karakter, post başına 5 etiket (trigger); oluşturma ekranlarına `maxLength`; RPC `22023` → `ValidationFailure`. Profil alanları UX-8'de. _(2026-10-25; canlıda, smoke 13 geçti)_ — `DATA-17`
- [x] Paylaş butonu kaldırıldı — `BUG-11`
- [x] Ortak takipçiler: profili takip edenlerden benim takip ettiklerim (`mutualFollowersProvider`); kendi profilinde gizli. _(2026-10-25; testli, cihazda doğrulandı)_ — `BUG-19` Başlık yenilenirken (d8fb60d) düşmüştü; 2026-11-08 Instagram tarzı tek satırla (24px üst üste avatarlar, "A, B ve N kişi daha takip ediyor", dokununca takipçiler) sayaçlarla butonlar arasına geri eklendi.
- [x] Bildirim ayarları toggle'ları kaldırıldı (DB tercihi ve push yok); tercihler Faz 5'te push ile gelir — `UX-4`
- [x] Integration test fake repository'lerle (`integration_test/fake_repositories.dart`); koşullu assertion yok; aynı akış headless `test/app_flow_test.dart` ile `flutter test`'te ve GitHub Actions CI'da (`.github/workflows/ci.yml`: analyze + test) koşar. _(2026-10-25; yerelde, Android emülatörde ve CI'da yeşil)_ — `TEST-2`

**Bitti tanımı:**
- İki gerçek hesapla: beğeni, yorum ve takip karşı tarafa bildirim olarak düşüyor; okunmamış rozeti artıp azalıyor.
- Mesaj anında geliyor.
- Post düzenlenebiliyor; görsel yüklemesi yarıda kesilince yarım post kalmıyor.
- Integration test CI'da yeşil.

**Durum (2026-10-25):** Faz 1 kapandı. `flutter analyze` hatasız, `flutter test` 233/233, migration 001–017 local = remote, smoke 12–13 geçti, integration test Android emülatörde ve GitHub Actions CI'da yeşil; bildirim, mesaj ve post düzenleme iki hesapla cihazda doğrulandı.

---

## Faz 2 — Ölçek & dayanıklılık ✅

- [x] Cursor (keyset) sayfalama + sonsuz kaydırma: feed, yorumlar, arama, mesajlar, takipçiler, bookmark'lar. Liste sonundaki `LoadMoreFooter` göründükçe sonraki sayfayı ister (sohbette yukarı kaydırınca eski mesajlar); yorumlarda "Daha fazla göster" butonu. Silme ve profil etkileşimi yüklenen sayfaları korur (tek öğe güncellenir). Sohbet listesi sayfasız. Ortak takipçiler migration 018 `get_mutual_followers` RPC'siyle DB'de kesişimden (ilk 3 kişi + toplam; canlıda, anon erişimi kapalı, cihazda doğrulandı). _(2026-10-25; testli, tüm listeler cihazda doğrulandı)_ — `DATA-12`
- [x] Görsel sıkıştırma: picker uzun kenarı 2048px'e indirir, yükleme anında `compressToWebp` (`core/utils/image_compress.dart`, `flutter_image_compress`) WebP q80'e çevirir ve EXIF/konumu atar; kodlanamazsa orijinal yüklenir. Migration 019: `post-images` ve `avatars` için 2MB sunucu limiti (canlıda). _(2026-10-25; testli, cihazda doğrulandı: Storage'da WebP, boyut ~yarıya indi, exiftool: EXIF yok)_
- [x] `post-images` private (migration 020): okuma yalnızca oturumlu kullanıcı; repository sayfadaki tüm görselleri tek `createSignedUrlsResult` isteğiyle 1 günlük imzalar, imzalanamayan (silinmiş) dosya atlanır; `CachedNetworkImage` önbelleği dosya yoluna bağlı (token değişse de yeniden indirmez). _(2026-10-25; testli, canlıda: public endpoint "Bucket not found" dönüyor; cihazda doğrulandı 2026-10-25)_ — `SEC-9`
  - **Bilinen sınır:** 020'den önce açık URL'si çekilmiş 5 dosya Supabase Smart CDN'de (Cloudflare) önbellekte kaldı; eski `/object/public/…` linkleri `cf-cache-status: HIT` ile hâlâ açılıyor. Bucket'ı private yapmak, dosyayı taşımak, silip yeniden yüklemek bu önbelleği temizlemedi (2026-10-25, 3+ dk izlendi). Yeni yüklemeler etkilenmez. Bu 5 dosya test verisi; kabul edildi. Gerçek veride aynı durum olursa Supabase desteğinden purge istenir. Eski uygulama sürümünde yeni yüklenen görsellerin açılmadığı cihazda doğrulandı (2026-10-25).
- [x] Tutarlı hata yönetimi: feed, arama, bookmark, takip, görüntülenme ve kayıt/oturum metotları da `guardSupabase` ile sarıldı; "oturum yok" artık `AuthRequiredFailure`. `23505` → `ConflictFailure` (kayıttaki kullanıcı adı yeniden denemesi buna bağlı), `StorageException` durum koduna göre (413 → `ValidationFailure`, 401/403/404). Kapsam dışı: `sendOtp`/`verifyOtp` (giriş ekranının kendi mesajları var, AUTH-10) ve realtime stream'ler. _(2026-10-25; testli)_
- [x] Offline banner + yeniden deneme: `connectivity_plus` ile `isOnlineProvider`; çevrimdışıyken tüm ekranların üstünde şerit (`OfflineBanner`, `MaterialApp.builder`). Bağlantı geri gelince sohbetler, açık sohbet ve bildirimler yeniden çekilir (realtime kopukken kaçan olaylar), feed hatadaysa kendiliğinden yeniden dener. Post detayı ve düzenleme hata ekranına "Tekrar Dene" eklendi; diğer listelerde zaten vardı. Bilinen sınır: Wi-Fi var ama internet yoksa şerit çıkmaz, o durumda ekranların hata + Tekrar Dene akışı devrede. _(2026-10-25; testli, cihazda şerit doğrulandı; yeniden bağlanınca tazeleme cihazda doğrulandı 2026-10-25)_
- [x] Arka plandan dönünce tazele: uygulama gizlenip yeniden görününce (`appResumeProvider`, `AppLifecycleListener.onShow`) bağlantı geri gelmiş gibi sohbetler, açık sohbet ve bildirimler yeniden çekilir, realtime kanalları yeniden kurulur. Önceden arka planda gelen mesaj ve rozet ancak elle yenileyince görünüyordu. _(2026-10-29; testli, cihazda doğrulandı 2026-10-29)_
- [x] Oturum düşmesi: `AuthRepository.signedOut` (`onAuthStateChange` → `signedOut`) dinlenir, auth state null olur; router login'e yönlendirir, kullanıcıya özel provider'lar temizlenir. Bilinen sınır: kayıt ekranındayken (profil yok) oturum düşerse kullanıcı bir sonraki gezinmede login'e gider. _(2026-10-25; testli, cihazda doğrulandı 2026-10-25)_ — `AUTH-5`
- [x] Sayaç uzlaştırma: migration 021 `reconcile_counters()` (SECURITY DEFINER, istemciye kapalı) tüm sayaçları kaynak tablolardan yeniden sayar, yalnızca farklı satırları düzeltir ve düzeltilen satır sayılarını jsonb döner; SQL Editor'dan `select public.reconcile_counters();` ile çalıştırılır (zamanlama yok, pg_cron gerekirse sonra). `>= 0` CHECK'leri canlıda 001'den beri zaten varmış (AUDIT tespiti hatalıydı); 021'in eklediği `*_nonneg` CHECK'leri tekrar, zararsız. Trigger'lardaki `GREATEST(…,0)` kaldı (sapmada unlike hata vermesin). _(2026-10-25; canlıda, sapma 0 satır, smoke 14 geçti)_ — `DATA-18`
- [x] `searchUsers` oturumsuzken kendini dışlama filtresini atlar — `DATA-20`

**Bitti tanımı:** Seed ile 1.000+ post ve 200+ mesaj varken feed ve chat akıcı kayıyor; uçak modunda uygulama çökmüyor, anlamlı bir mesaj gösteriyor.

**Yük testi (2026-10-25):** `supabase/scripts/load_test_seed.sql` canlı dev projesine uygulandı (1.000 post + 200 mesaj, hepsi `[seed]` önekli; geri almak için `load_test_cleanup.sql`). `EXPLAIN ANALYZE` (authenticated, RLS açık): 30. feed sayfası 0,57 ms, sohbet sayfası 0,39 ms, ikisi de indeksli. Feed planında imleç `or`'u indeks koşulu olmadığı için derin sayfa baştan taranıyordu (601 satır atlandı); `keyset.dart` artık `created_at` sınırını da gönderiyor, 0,23 ms / 1 satır. Cihazda feed ve sohbet kaydırma ile uçak modu doğrulandı.

**Durum (2026-10-25):** Faz 2 kapandı. `flutter analyze` hatasız, `flutter test` 257/257, migration 001–021 local = remote, smoke 14 geçti; seed verisiyle feed ve sohbet cihazda akıcı kayıyor, uçak modunda uygulama çökmüyor ve şerit + Tekrar Dene görünüyor.

---

## Faz 3 — UX cilası & yerelleştirme ✅

- [x] Sabit metinler ARB'ye taşındı (~130 yeni anahtar, TR+EN). Enum adları `displayName(context)` extension'ında (`user_title_ui`, `dental_branch_ui`), modelde metin kalmadı. `getErrorMessage(l10n, e)`; context'i olmayan controller'lar `l10nProvider` kullanır. Arama ekranlarındaki ham `ValidationFailure.message` gösterimi kaldırıldı. Göreli zaman ARB'den, 30+ gün tarihi `intl` ile. `test/core/no_hardcoded_text_test.dart` Türkçe karakterli sabitleri yakalar. Metin değişiklikleri: tema seçenekleri "Açık/Koyu/Sistem Varsayılanı", kullanıcı arama alanı "Ara", ortak takipçi satırında kalın vurgu yok. _(2026-10-25; İngilizce'de cihazda bakıldı, Türkçe metin yok 2026-10-25)_ — `UX-12`
- [x] Boş, hata ve yenileme durumları: sohbet listesine `DentigoEmptyState`; bildirimler, sohbetler, takipçi/takip edilen ve profil gönderi sekmelerine çekerek yenileme (feed ve kaydedilenlerde zaten vardı). Yenilenirken mevcut liste ekranda kalır. _(2026-10-25; test yok, cihazda doğrulandı 2026-10-25)_ — `UX-7`
- [x] `PopScope`: ortak `UnsavedChangesScope` (vaka/soru oluşturma, post ve profil düzenleme). Gönderirken geri tuşu çalışmaz; form dokunulmuşsa onay diyaloğu (TR+EN); kaydedip çıkış etkilenmez. _(2026-10-25; testli)_ — `UX-2`
- [x] Uzunluk ve taşma: profil alanlarına sınır (ad 60, biyografi 300, üniversite/şehir/klinik 100; kayıt ve profil düzenleme, `ProfileLimits`), kayıtta da deneyim yalnızca rakam; migration 022 DB CHECK'leri (canlıda). Feed kartı başlığı `maxLines: 2`; post başlığındaki ve yorumdaki uzun isimler tek satır + ellipsis. Profil düzenleme: alanlar trim, deneyim yalnızca rakam (UX-10). _(2026-10-25; testli)_ — `UX-8`, `UX-9`, `UX-10`
- [x] Erişilebilirlik: yalnızca ikonlu butonlara tooltip (geri/temizle Material metinleri, gönder, devam, yeni mesaj, beğen, kaydet); detaydaki daire butonlar `IconButton`. 48dp dokunma alanı: beğeni/kaydet, yorum sayacı, aksiyon satırı, tıklanabilir avatarlar, alt menü "+", görsel kaldırma. Kontrast: yorum/cevap ipucu temadan, koyu tema `darkTextTertiary` ~5.6:1, alt menü etiketi 12px. `test/a11y_guidelines_test.dart` feed ve vaka detayında Flutter'ın `androidTapTargetGuideline` ve `labeledTapTargetGuideline` kontrollerini koşar. Görsel değişiklik: kartlarda aksiyon satırı 48px, avatar ve beğeni ikonu çevresinde boşluk arttı. _(2026-10-25; cihazda doğrulandı 2026-10-25, en büyük yazı boyutunda taşma yok)_ — `UX-13`, `UX-14`, `UX-15`
- [x] Sabit renkler: marka teal'i (`0xFF13B9A5`, beyaz üzerinde ~2.5:1) yerine `colorScheme.primary`; koyu arka plan `AppColors.darkBackground`; kayıt diyaloğu tema rengini kullanır; branş renkleri `AppColors.branch*`. `lib/`'de `AppColors` ve tema dışında `Color(0x…)` kalmadı, `test/core/no_color_literals_test.dart` bunu korur. Görsel değişiklik: auth ve ayarlar ekranlarındaki teal, light temada daha koyu. _(2026-10-25; cihazda doğrulandı 2026-10-25)_ — `UX-16`
- [x] Tema tercihi kalıcı: `SharedPreferences` `main`'de önceden yüklenir (açılışta tema yanıp sönmez). _(2026-10-25; testli)_ — `UX-11`
- [x] Bookmarks ekranı: beğeni çalışıyor (iyimser, feed ve aramaya yansır); kaydırma ve bookmark ikonu aynı akış: onaysız kaldırır, "Geri Al" postu eski sırasına koyar; kaldırma/geri alma feed ve aramadaki bookmark durumunu da günceller. _(2026-10-25; testli)_ — `BUG-24`
- [x] Kayıt başarı diyaloğu yarışı: kayıt sürerken ve diyalog açıkken `authRedirectHoldProvider` tutulur. Hazır avatarlar kaldırıldı (karar 2026-10-25); fotoğraf seçilmezse ikon gösterilir. _(2026-10-25; widget testli)_ — `BUG-21`, `AUTH-8`
- [x] Login küçük UX düzeltmeleri: geri sayım 60 sn (limiter ile aynı), yalnızca sunucunun reddettiği kod "Kod hatalı", ağ ve diğer hatalar `getErrorMessage` ile; dispose sonrası state yazılmaz. _(2026-10-25; testli)_ — `AUTH-10`
- [x] Domain katmanı kaldırıldı (karar 2026-10-25): `enums.dart` → `lib/data/models/`, `CommentEntity` → `CommentModel` (yazar `UserModel`, satır parse `CommentModel.fromRow`), `CommentRepository` arayüzü `lib/data/repositories/`; kullanılmayan `UserEntity`, `UserSummary`, `UserMapper`, `CommentMapper` silindi. Tek unvan varsayılanı `UserModel.fromJson`. — `DATA-19`
- [x] Ölü kod: ~~`FeedMode`~~ (DATA-12 ile kaldırıldı, `BUG-26` ✅); sohbet kullanıcı aramasında gerçek debounce: 300 ms içinde yeni harf gelirse önceki sorgu istek atmaz. _(2026-10-25; testli)_ — `BUG-22`
- [x] Etiket önerisi: migration 025 `tags.is_curated` + ~80 tanımlı branş etiketi (tek kelime ya da tireli) ve `suggest_tags` RPC (ad ya da ASCII slug içinde arar, başı eşleşen önce, en fazla 8). `TagInput` 2 karakterden sonra 300 ms debounce ile öneri listesi açar (vaka/soru oluşturma, düzenleme); eklenmiş etiket önerilmez, serbest etiket yine eklenebilir, öneri hatası sessizce boş liste. Başarılı paylaşım artık postun detayını açar (form kapanır). _(2026-10-25; testli, 025 canlıda, smoke 19 geçti (80 etiket; "imp", "cene" sonuç veriyor, anon kapalı), cihazda doğrulandı 2026-10-25)_

**Bitti tanımı:** Uygulama dili İngilizce'ye alınınca hiçbir Türkçe metin görünmüyor; en büyük yazı boyutunda ekranlar taşmıyor.

**Durum (2026-10-25):** Faz 3 kapandı. Uygulama İngilizce'ye alınınca Türkçe metin görünmüyor, en büyük yazı boyutunda ekranlar taşmıyor (cihazda). `flutter analyze` hatasız, `flutter test` 277/277, migration 001–025 local = remote, smoke 15–19 canlıda geçti.

---

## Faz 4 — Moderasyon & hukuk 🛡️ (MVP için zorunlu)

- [x] İçerik ve kullanıcı **raporlama**: migration 023 `reports` (istemci yalnızca ekler, okuyamaz; aynı hedef bir kez, tekrarı sessizce yok sayılır). Post kartı menüsü sahibine Düzenle/Sil, başkasına Raporla/Engelle; post detayı, yorum, profil ve sohbette ⋮ menüsü. Rapor sheet'i: 6 sebep (hasta mahremiyeti dahil), 500 karakter not, gönderirken kilitli. _(2026-10-25; testli, 023 canlıda, smoke 15–17 iki hesapla geçti (2026-10-25), raporlama cihazda doğrulandı 2026-10-25)_ — `UX-6`
- [x] Kullanıcı **engelleme**: migration 023 `blocks` + `is_blocked_between` (iki yönlü). `posts` ve `comments` SELECT policy'leri engelli çifti gizler, `send_message` 42501 döner, takip edilemez; engellenince iki yöndeki takip silinir. Eski mesaj geçmişi görünür kalır. İstemci yazarın postlarını feed'den, aramadan ve açık yorum listesinden yerelde çıkarır. Ayarlar → Engellenenler (iyimser engel kaldırma + rollback). Arkasında özellik olmayan "Gizlilik" satırı kaldırıldı. _(2026-10-25; testli, 023 canlıda, smoke 15–17 iki hesapla geçti (2026-10-25), **cihazda denenmedi**)_ — `UX-6`
- [x] Moderasyon kuyruğu: Dashboard SQL Editor, sorgular [`SUPABASE.md`](./SUPABASE.md) §6. Smoke 15–17 eklendi.
- [x] **Hesap silme** (karar 2026-10-25: Edge Function yerine SQL RPC): migration 024 `delete_account()` `auth.users` satırını siler, veriler cascade ile gider (karşı taraftaki sohbet dahil). İstemci önce `avatars/{uid}` ve `post-images/{uid}` klasörlerini sayfa sayfa boşaltır; dosyalar silinemezse RPC çağrılmaz. Ayarlar → Hesabı Sil: onay kelimesi (SİL/DELETE) yazılmadan buton kapalı, silerken kilitli. _(2026-10-25; testli, 024 canlıda, smoke 18 geçti (2026-10-25), cihazda denenmedi)_ — `UX-5`
- [x] KVKK aydınlatma metni, gizlilik politikası, kullanım koşulları: **taslak** TR+EN metinler `assets/legal/*.txt` (başlarında "hukukçu onayı bekleniyor"; şirket unvanı, adres, e-posta, yurt dışı aktarım dayanağı `[…]` yer tutucusu). `/legal/:doc` ekranı (oturumsuz da açılır), Ayarlar → Hakkında'da üç satır. Kayıt adım 1'de koşul onayı zorunlu (DB'ye yazılmıyor; hukukçu isterse `terms_accepted_at`). **Web sürümü Faz 5'e kaldı** (mağaza listelemesi gizlilik linki ister). _(2026-10-25; testli)_
- [x] Hasta mahremiyeti: vaka oluşturmada "yüz ve kimlik bilgisi içermiyor" onay kutusu zorunlu (işaretlenmezse SnackBar). Soru ekranında görsel yükleme olmadığından orada yok. _(2026-10-25; widget testli, cihazda doğrulandı 2026-10-25)_
- [x] **Yorumlara yanıt** (Reddit tarzı, sınırsız derinlik): migration 026 `comments.parent_id` (ebeveyn silinince alt ağaç da silinir) + trigger'lı `reply_count`; yanıt aynı posta ait olmalı, engelli çift birbirine yanıt veremez; en iyi cevap yalnızca üst seviye yorum; yanıt bildirimi (`reply`) yanıtlanan yorumun sahibine; `reconcile_counters` `reply_count`'u da düzeltir. İstemci: üst seviye yorumlar ve her yorumun yanıtları ayrı sayfalı listeler (`commentsProvider`, `repliesProvider`, ortak `CommentThreadNotifier`). Yorum kartında "Yanıtla" ve "N yanıtı göster"; yanıtlar girintili thread çizgisiyle, 4. seviyeden sonra girinti artmaz. Yanıtla alt giriş alanını yanıt moduna alır ("Yanıtlanan: …", ✕ ile iptal); gönderince ebeveynin yanıtları açılır. _(2026-10-27; widget testli, 026 canlıda (2026-10-29), smoke 20 ve cihaz testi bekliyor)_
- [ ] Kullanıcı doğrulama (diploma veya oda kaydı yükleme + admin onayı → `is_verified`). **Bekliyor:** resmi gereklilik ve belge türü araştırılıyor (karar 2026-10-25)
- [x] Ayarlar: sürüm bilgisi `package_info_plus` ile (`pubspec` sürümü + build no), çıkış onay diyaloğu. _(2026-10-25)_ — `UX-5`

**Bitti tanımı:** App Store ve Google Play inceleme gereksinimleri (UGC raporlama, engelleme, hesap silme, politika linkleri) karşılanıyor.

---

## Faz 5 — Yayın 🚀

- [ ] Uygulama adı, `applicationId`/bundle id, ikon, splash — `REL-4`, `UX-17`, `AUTH-11`
  - [x] `applicationId`/bundle id: `com.atlas.dentlink` (Firebase `dentlink-ea0f2`) _(2026-10-29)_
- [ ] Fontları bundle'a ekle — `REL-3`
- [ ] Android release imzalama (`key.properties`), R8 — `REL-2`
- [ ] iOS imzalama ve provisioning
- [ ] Production Supabase projesi + `--dart-define-from-file` (dev/prod) — `SEC-15`
- [ ] E-posta OTP şablonu ve SMTP; `site_url` — `AUTH-9`
  - [ ] Canlıya uygula: `supabase/scripts/apply_auth_config.mjs` (`SUPABASE.md` §10): e-posta girişi, 6 haneli kod, kod içeren şablon
  - [ ] `send-sms` hook'unu canlıya al (`SUPABASE.md` §10): sırlar, deploy, `SEND_SMS_HOOK_SECRET` ile config
  - [ ] Twilio WhatsApp göndericisi ve SendGrid SMTP bilgileri; `sms_test_otp` numaralarını temizle; cihazda uçtan uca test
- [ ] Crash raporlama (Sentry veya Crashlytics) — `REL-5`
- [ ] Push bildirim — `REL-6`
  - [x] Kod: migration 027 (`push_tokens`, `register/unregister_push_token`, pg_net trigger'ları), Edge Function `push` (FCM HTTP v1, geçersiz token temizliği), istemci `push_provider.dart` (izin, token kaydı, çıkışta silme, dokununca post/sohbet/profil). Bildirimler + DM. Firebase dosyaları yokken uygulama push'suz çalışır. Metin: başlık aktörün adı, gövde eylem + alıntı (post başlığı ya da yorumun başı, 029). Edge Function'ın okuduğu kolonlar `service_role`'e açıldı (028, 029). _(2026-10-29; rota testli, 027–029 canlıda)_
  - [x] Firebase projesi (`dentlink-ea0f2`), sırlar + deploy (`SUPABASE.md` §8); Android'de iki hesapla cihazda doğrulandı (mesaj, yorum) _(2026-10-29)_
  - [ ] iOS: `GoogleService-Info.plist`, APNs anahtarı, Push Notifications capability, cihaz testi; smoke 21
  - [ ] Ayarlarda bildirim tercihleri (`notification_preferences`, UX-4)
- [x] Etiket kataloğu ve tekilleştirme (migration 032): 464 tanımlı etiket (025'teki 80 + 384), 310 eş anlamlı (kısaltma, İngilizce, yaygın yanlış yazım). Aynı etiketin yazımları sunucuda tek etikete bağlanır: `match_key` (harf/Türkçe karakter/tire/boşluk farkı), `tag_aliases`, çoğul eki; mevcut tekrarlar birleştirilir. `suggest_tags` eş anlamlı ve yazım hatasında (pg_trgm) asıl etiketi, 3+ postta geçen kullanıcı etiketlerini de önerir. Yönetim ve aylık temizlik: `SUPABASE.md` §9. İstemci değişmedi. _(2026-10-31; katalog tutarlılık betiğiyle denetlendi, 032 canlıda, smoke 19 ve 22 geçti)_
- [x] Tedavi türleri (migration 033): 9 branşta 64 tedavi türü, her biri 032'deki bir tanımlı etikete bağlı (`treatment_types`). Vaka formunda branştan sonra tedavi türü seçilir (zorunlu; branş değişince sıfırlanır). Türün etiketi etiket alanında kilitli çip olarak görünür, 5 etiket sınırına dahildir ve sunucuda (`create_post`/`update_post`, `p_treatment`) posta zorunlu eklenir; tür branşa ait değilse 22023. `posts.treatment` kolonu; düzenlemede de seçilir, eski vakalar kaydederken tür seçer. İstemci listesi `TreatmentType` enum'u, TR/EN ARB; migration ile aynılığı testli. _(2026-10-31; analyze + 334 test geçti)_ 033 canlıda, smoke 23 geçti.
- [x] "Diğer" tedavi (migration 034): her branşta son seçenek "Diğer"; tedavi adı zorunlu, etiket önerili alan. Ad `resolve_tags`'ten geçer ve kilitli etiket olur (`posts.other_treatment_tag_id`). Listedeki bir tedavi yazılırsa öneride "listede var" görünür ve o tür seçilir; sunucu da aynı dönüşümü yapar (`case_treatment`). Sık yazılanlar onayla `promote_other_treatment` + enum/ARB ile listeye alınır (`SUPABASE.md` §9). `merge_tags` bu bağı da taşır. _(2026-10-31; analyze + 338 test geçti)_ 034 canlıda, smoke 24 geçti.
- [x] Keşfet yeniden tasarımı (migration 035): app bar yok; üstte arama satırı (metin ve `#etiket`, `#` yazınca `suggest_tags` önerileri), altında kısa adlı (Endo, Perio…; tam ad tooltip'te) alfabetik branş çipleri ("Tümü" başta, seçilen görünür alana kayar, kenarlar solar), "Popüler konular" (en çok postta geçen 5 etiket + post sayısı), metin aranıyorsa en fazla 3 kişi, "Popüler gönderiler". Sıra `post_hot_score`: (beğeni + 2×yorum + 2×kaydetme + 0,05×görüntülenme + 1) / (saat + 2)^1,5; `popular_post_ids` metin, etiket (eş anlamlılar dahil) ve branşla filtreler, offset sayfalı. Popüler etikete dokununca sorgu o etiket olur, branş Tümü; seçili etiket vurgulanır, tekrar dokununca kalkar. İçerik türü filtresi kaldırıldı. _(2026-11-01; analyze + 344 test geçti)_ 035 canlıda.
- [x] **Vaka arşivi: çoklu tedavi (migration 040).** Vakada 1–5 tedavi (ana/ek yok, seçim sırası); branş alanı kalktı, branşlar tedavilerden çıkar. Tedavi kimliği etiketi (`post_treatments`: post, etiket, branş, sıra); listedekinin branşı sabit, kullanıcının eklediğinde ("ekle" → branş sorulur) kullanıcı seçer ve arşivi hemen açılır. "Diğer" akışı, `posts.treatment` ve `other_treatment_tag_id` kalktı; mevcut vakalar taşındı. Tedavi etiketleri `post_tags`'te kalır (#etiket araması) ama 5 etiket sınırına sayılmaz. Seçim penceresi: arama (yerel ad + sunucuda eş anlamlı, `list_treatments`) ve branşa göz at; tam liste hiç gösterilmez. Kart: başlığın üstünde ilk 2 tedavi + "+N", branş adı yerine çip rengi (yeni palet, açık/koyu ≥ 4.5:1). Post sayfası: tedaviler branşa göre gruplu (branş → Keşfet). `/treatment/:slug` arşivi: en yeni/en popüler (`popular_post_ids` `p_treatment`, `p_recent`), Hero ile çip başlığa uçar. Keşfet: branş seçilince tedavileri (vaka sayılı), metin aranınca tedavi satırı; branş filtresi vakanın bütün tedavi branşlarına bakar. _(2026-11-02; analyze + 369 test geçti)_ 040 canlıda; smoke 23–25 bekliyor.
- [x] Yeni mesajda önerilen kişiler (migration 041, `suggested_user_ids`): + ile açılan arama boşken liste gelir. Sıra: takip ettiklerim, beni takip edenler, aynı üniversite, aynı şehir, en çok takipçi; kendisi, engellenenler ve kaydını bitirmeyenler çıkar. _(2026-11-04)_ 041 canlıda.
- [x] Beğenenler listesi (`/post/:id/likes`, takipçi listesiyle aynı görünüm, sayfalı, takip butonlu): kartta beğeniye basılı tutunca açılır, dokunmak yine beğenir. Migration 042: `likes` okuması engellenenleri iki yönlü gizler. _(2026-11-04)_ 042 canlıda.
- [x] Uygulama adı Dentigo: görünen ad, yasal metinler, Dart paketi ve sınıflar, rozet metni (migration 043). Dış kimlikler eski adla kalır: `com.atlas.dentlink`, Firebase `dentlink-ea0f2`, Supabase `dentlink_backend`. _(2026-11-04)_
- [x] Mesajlar ve sohbet görsel düzeni: listede büyük avatar, ayraçsız satırlar, boş durumda "Yeni mesaj"; sohbette gruplanan balonlar (saat ve avatar grubun sonunda), gün çipi, karşı tarafı tanıtan boş ekran, hap biçimli yazma alanı. _(2026-11-04)_
- [x] **Gönderide video ve forumda görsel (migration 046).** Vaka ve forumda en fazla 1 video (≤60 sn; kamerada `maxDuration`, galeride süre ölçülür). Gönderirken `video_compress` ile 720p mp4'ye sıkıştırılır (> 50 MB ise reddedilir); sıkıştırma kaynak videonun konumunu kopyaladığı için (Transcoder `setLocation`, iOS export) ardından `stripMp4Metadata` film/iz düzeyi `udta`/`meta` kutularını `free`'ye çevirip sıfırlar (konum, cihaz, tarih; boyut ve `mdat` değişmez) ve JPEG kapak çıkarılır. Video private `post-videos` bucket'ında (50 MB, `video/mp4`); video da bir `post_images` satırı (kapak `image_url`, video `video_path`, posta en fazla 1), böylece görsel ve video tek `sort_order` ile sıralanır. `create_post` `p_video_path` + `p_video_index` (kapağın `p_image_paths`'teki yeri; yollar kullanıcının klasöründe olmalı, video medya sınırına sayılır: vaka 10, forum 4). **Sıralama:** paylaşırken ve düzenlerken medya basılı tutup sürüklenerek sıralanır (`MediaReorderStrip`); düzenlemede ekleme/silme yok, `update_post` `p_media_order` (postun bütün medya id'leri, tam bir kez). Kartta ve tam ekran galeride video kendi sırasında kapak + oynat simgesiyle. Kartta videoya da dokununca galeri o sayfadan açılır ve video galerinin içinde hemen oynar (`GalleryVideo`, `video_player`; dokun durdur, ilerleme çubuğu); kaydırınca diğer medya, sayfadan çıkınca video durur, kaydırarak gelinen videoda kapak + oynat simgesi. Forum formuna görsel/video seçici; medya varsa mahremiyet onayı. Silme ve hesap silme videoyu da temizler. _(2026-11-07; analyze + 407 test geçti)_ 046 canlıda, smoke 26 geçti. **Cihazda Android/iOS build, yükleme ve oynatma henüz denenmedi.**
- [ ] **Sürüm kontrolü ve zorunlu güncelleme** (ilk yayından önce şart: 1.0'da kontrol yoksa o sürüm sonradan hiç zorlanamaz)
  - **Politika:** güncelleme varsayılan olarak önerilir, zorlanmaz. Zorlama yalnızca eski sürüm gerçekten bozulduğunda: geriye uyumsuz şema/RPC değişikliği, güvenlik açığı, veri kaybı bug'ı, hukuki zorunluluk (KVKK, yeni politika metni). Süre takvimle değil kararla belirlenir; zorlama sunucudan açılır, uygulama sürümü gerekmez.
  - **Migration 038 `app_config`:** platform başına bir satır (`android`, `ios`): `min_supported_version`, `latest_version`, `store_url`, `updated_at`. RLS: `anon` ve `authenticated` yalnızca SELECT (oturum açmadan da okunur); yazma yalnızca Dashboard/`service_role`. Sürüm alanı `x.y.z` CHECK'li metin. Başlangıç değerleri ilk yayın sürümü. Smoke: anon okuyabiliyor, yazamıyor.
  - **İstemci:** `AppConfigRepository` (`guardSupabase`) + `appVersionStatusProvider`; mevcut sürüm `package_info_plus`'tan. Sonuç üç durumdan biri: `upToDate`, `updateAvailable` (`< latest`), `updateRequired` (`< min`). Karşılaştırma `x.y.z` sayısal (`1.10.0 > 1.9.0`); build no karşılaştırılmaz. Açılışta ve arka plandan dönünce (`appResumeProvider`) yeniden okunur.
  - **Hata durumu açık kalır:** config okunamazsa (çevrimdışı, ağ hatası, satır yok, sürüm parse edilemez) durum `upToDate` sayılır; sunucuya ulaşılamadı diye kimse kilitlenmez.
  - **Zorunlu:** `updateRequired` iken router redirect (auth guard'dan önce) `/update-required` ekranına gider; oturumlu ve oturumsuz tüm rotalar bloklanır, geri tuşu çıkamaz. Ekranda açıklama + tek buton "Mağazaya git" (`store_url`; `url_launcher` henüz yok, eklenecek). Uygulama dönünce yeniden kontrol edilir, sürüm yeterliyse normal akışa döner.
  - **Önerilen:** `updateAvailable` iken feed üstünde kapatılabilir banner ("Yeni sürüm var" + Güncelle). Kapatma `SharedPreferences`'ta o `latest_version` için saklanır; yeni `latest` gelince yeniden görünür.
  - Metinler TR+EN ARB; renkler temadan.
  - **Testler:** sürüm karşılaştırma (eşit, büyük, küçük, `1.10` vs `1.9`, bozuk girdi), provider'ın üç durumu + hata → `upToDate`, redirect (`updateRequired` her rotayı `/update-required`'a götürür), banner kapatma kalıcılığı.
  - **Yayın akışı** (`SUPABASE.md`'ye bölüm olarak eklenecek):
    1. Normal sürüm: mağazada yayınlandıktan sonra (kademeli dağıtım bitince) yalnızca `latest_version` artırılır.
    2. Şema değişikliği: expand/contract. Önce eskiyi bozmayan migration (yeni kolon/RPC eklenir, eskisi kalır) → yeni sürüm yayılır (1–2 hafta, eski sürüm kullanımı ~%5 altına inene kadar; Crashlytics/Sentry sürüm dağılımından) → `min_supported_version` artırılır → eski kolon/RPC'yi silen contract migration.
    3. Acil güvenlik açığı: düzeltilmiş sürüm mağazada onaylanınca `min_supported_version` hemen artırılır.
  - **Kapsam dışı (şimdilik):** Google Play yerel in-app update API'si (`in_app_update`; yalnızca Android, iOS karşılığı yok). Gerekirse sonradan Android'de mağazaya gitmek yerine eklenir.
- [ ] **Destek sohbeti ve personel rolleri.** Kullanıcı destek ekibine Mesajlar'ın sağ altındaki destek butonundan açılan "Dentigo Destek" sohbetinden yazar; kullanıcı başına tek, sürekli sohbet (bilet numarası yok). Normal DM değil: sohbet ekibe ait, personel kendi hesabıyla ve adıyla cevaplar. Roller (`support`, `moderator`, `admin`) ileride admin panelinin ve moderasyonun da temeli; panel aynı RPC'leri ve RLS'i kullanır, `service_role` istemciye girmez.
  - [x] Migration 049: `staff` + `has_staff_role`, `support_threads` (durum `open`/`answered`/`resolved`, kategori, `client_info`, atanan, okundu zamanları, `first_response_at`), `support_messages` (`internal` iç not kullanıcıya görünmez). Yazma yalnızca RPC: `send_support_message` (10 dk'da 20 mesaj sınırı), `reply_support`, `set_support_status`, `mark_support_read`. Realtime'a eklendi. Kullanım ve smoke 28–30: `SUPABASE.md` §11. _(2026-11-08; canlıda, smoke 28–30 geçti 2026-11-09)_
  - [x] İstemci: `SupportRepository`, `/support` (sohbet balonları yeniden kullanılır, cevap "Dentigo Destek · Ad"), Mesajlar'ın sağ altında destek butonu (okunmamış cevapta rozet, alt menü rozetine de sayılır; durum Açık/Yanıtlandı/Çözüldü sohbet başlığında), son mesajın altında not ("Mesajınızı aldık… 24 saat içinde" / "Destek ekibi okudu" / "Çözüldü"), ilk mesajda isteğe bağlı kategori, platform ve sürüm otomatik eklenir. Giriş: Ayarlar → Hakkında → "Destek ile iletişim". TR+EN. _(2026-11-09)_
  - [ ] Hata ekranlarında "Sorun bildir" girişi.
  - [ ] Push: personel cevabında kullanıcıya bildirim (027 kalıbı), dokununca `/support`.
  - [ ] Admin paneli (uygulama dışı): destek kutusu (açıklar üstte, en eski bekleyen önce), cevap, iç not, durum, atama, ilk cevap süresi; yeni mesajda ekibe haber panelden. Sonra moderasyon kuyruğu ve diploma onayı. Uygulamaya personel kutusu eklenmez.
  - [ ] Sonra: ek (ekran görüntüsü), çözülünce 👍/👎.
  - **Kararlar (2026-11-09):** kullanıcıya söylenen cevap süresi "genelde 24 saat içinde"; destek talepleri ve ekip bildirimleri admin panelinden.
- [ ] Performans profili (başlatma süresi, jank, bellek)
- [ ] Beta testi (TestFlight + Play Internal) → mağaza açıklamaları ve ekran görüntüleri → yayın

---

## Yayın sonrası (backlog)

- Algoritmik feed (etkileşim skoru, `post_views`)
- ~~Etiket önerisi ve otomatik tamamlama~~ (Faz 3, 025), etikete tıklayınca filtre
- Rozet ve başarım sistemi (`BadgeShowcase` zaten var)
- İş ilanları (`JobPostModel`); pazar yeri Ticaret olarak geldi (052)
- Google ve Apple ile giriş (iOS'ta Google varsa Apple zorunlu)
- Deep link ile post/profil paylaşımı
- Onboarding slaytları
- Riverpod 3 ve go_router güncel major sürümlerine geçiş — `REL-7`

---

## Açık kararlar

| Konu | Ne zaman |
|---|---|
| ~~Kayıtta hazır avatar seçeneği kalsın mı?~~ Kaldırıldı (2026-10-25) | Faz 3 ✅ |
| ~~Domain katmanı: tamamla mı, kaldır mı?~~ Kaldırıldı (2026-10-25) | Faz 3 ✅ |
| Doğrulama belgesi türü (diploma / TDB oda kaydı) | Faz 4 |
| ~~Pazar yeri: feed'de mi, ayrı sekmede mi?~~ Ayrı "Ticaret" sekmesi, "Tümü"ye karışmaz (2026-11-09) | ✅ |
- [x] WhatsApp ve e-posta ile kayıt/giriş (uygulama tarafı): telefona kod WhatsApp kanalından gider (Twilio), numara yazımları tek E.164 biçimine iner (`contact_utils.dart`), WhatsApp'tan kopyalanan kod kutulara yapıştırılır. Ayarlar → Hesap'tan e-posta/WhatsApp numarası eklenir ya da değiştirilir (`/settings/contact/*`), kod yeni adrese gider. Yasal taslaklara Twilio ve Meta eklendi. Migration yok. Canlı ayarlar yukarıda bekliyor. _(2026-11-04)_
- [x] Giriş akışı düzeltmeleri: açılışta oturum geri yüklenirken form yerine yükleniyor göstergesi; geçersiz girişte açıklama; adres sıklık sınırı (sunucunun bildirdiği süre) ile genel limit ayrıldı, genel limitte OTP adımı açılmaz; çok deneme "kod hatalı" görünmez; yeniden gönderimde WhatsApp hatası; doğrulama sürerken geri kapalı; kayıtta çift gönderim yok. _(2026-11-04)_
- [x] Giriş akışı: Android geri tuşu OTP ve kayıtta önceki adıma döner; kayıt başlığındaki geri ve "Geç" çalışır; OTP tek gizli alana taşındı (boş kutuda silme, yapıştırma, kod önerisi). _(2026-11-04)_
- [x] Migration 044: profilsiz auth kullanıcıları saat başı silinir (doğrulanmamış 1 saat, doğrulanmış 24 saat), yanlış yazılan numara gerçek sahibini kilitlemez. 043 ve 044 canlıda. _(2026-11-04)_
- [x] "Benzer vakalar" post sayfasından kaldırıldı: bölüm, provider, repository metodu ve metinler silindi; migration 045 `related_case_ids` fonksiyonunu kaldırır. 045 canlıda (2026-11-07).
- [x] WhatsApp girişi yalnızca Türkiye cep numaralarını kabul eder (`normalizePhone`, giriş ve Ayarlar → Hesap). Sunucu kısıtı: Send SMS hook'u `send-sms` giriş, kayıt ve numara değişiminde yabancı numarayı reddeder, WhatsApp'ı kendisi gönderir (`SUPABASE.md` §10). _(2026-11-06)_
- [x] Keşfet'te "Popüler konular" yerine "Popüler kişiler": yalnızca Tümü'de ve arama yokken en fazla 5 kişi. Skor, kişinin son 30 gündeki postlarının `post_hot_score` toplamı (migration 047, `popular_user_ids`) + 0,25 × yorumlarının skoru, (beğeni + 2×yanıt) / (saat + 2)^1,5, taban puan yok (048); kendisi, engellenenler ve kaydını bitirmemişler dışlanır. Etiket linkleri (post sayfası) Keşfet'i hâlâ o etiketle açar. _(2026-11-08; analyze + 430 test geçti)_ 047 ve 048 canlıda, smoke 27 geçti (2026-11-08).
- [x] "Popüler kişiler" başlığının sağındaki "Tümünü gör ›" ilk 50 kişiyi sıra numarasıyla açar (`/popular-people`, sekme içinde); `popular_user_ids` üst sınırı 20 → 50 (migration 050). Numara herkes için aynı gerçek sıra (`popular_users_ranked`): kişi kendini de görür, engellenen kişi çıkar ve numarası atlanır (yer tutucu yok, kimin engellediğini ele verirdi); Keşfet'in 5'i de bu sıranın ilk 5'i, kişi orada da kendini görür. İlk 50'deki kişinin profilinde adının altında "Popüler #N" çipi (`popular_user_rank`; dokununca liste). `popular_user_ids` eski sürümler için kalır. Hiç etkileşim almamış kişiler (beğeni, yorum, kaydetme, yanıt yok) listeye girmez; skor ortak `popular_user_scores`'ta. _(2026-11-09; analyze + 445 test geçti)_ 050 canlıda, SQL Editor ve uygulama testi geçti (2026-11-09).
- [x] Yorum thread çizgisi: düz sol kenarlık yerine ebeveynin avatarının altından inen ince çizgi, her yanıtın avatarına yuvarlak dirsekle bağlanır, son yanıtta biter (`_ThreadLinePainter`); yanıt girintisi daraldı. Girinti bittikten sonra (5. seviye ve altı) çizgi yok, yanıt metni "@Ad" ile başlar. _(2026-11-08; widget testli, analyze + 432 test geçti)_
- [x] **Ticaret (2. el malzeme ilanı, migration 051–052).** Yeni post türü `listing` (`ListingPostModel`): başlık, açıklama, 1–6 fotoğraf (video yok), kategori (El aletleri, Döner aletler, Cihaz ve ekipman, Sarf malzeme, Kitap ve not, Fantom ve model, Diğer), durum (Sıfır / Az kullanılmış / Kullanılmış), şehir (profildeki gelir) ve isteğe bağlı fiyat (TL; boşsa "Fiyat sorunuz"). Etiket, beğeni ve yorum yok (DB trigger'ı da reddeder), kaydetme var. Uygulama yalnızca ilanı barındırır: post sayfasında "Satıcıya yaz" sohbeti hazır mesajla açar (`/chat/:id?text=`), alt notta "ödeme ve teslimat taraflar arasında". Sahibi "Satıldı olarak işaretle" / "Yeniden satışa çıkar" (`set_listing_sold`); satılan ilan Ticaret'ten ve Keşfet'ten düşer, linkle ve kaydedilenlerde "Satıldı" ile görünür. Feed'de ayrı "Ticaret" sekmesi (kategori çipleri, sunucuda filtre, `getListings`); ilanlar "Tümü"ye karışmaz (`getFeed` ilanı dışlar), Keşfet'te yalnızca metin aramasında çıkar (`popular_post_ids`). Oluştur menüsünde "İlan Ver"; yasaklı ürün onayı zorunlu. Düzenlemede kategori, durum, fiyat ve şehir değişir (`update_listing`). Profilde "İlanlar" sekmesi. Rapor sebebi "Yasaklı ürün ya da dolandırıcılık" (`prohibited_item`). _(2026-11-09; analyze + 451 test geçti)_ 051 ve 052 canlıda (2026-11-09). **Cihazda uçtan uca denenmedi.**
