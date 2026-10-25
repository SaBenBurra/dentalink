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
| Faz 2 | Ölçek & dayanıklılık: keyset sayfalama, görsel sıkıştırma, private `post-images`, tutarlı hata eşleme, offline banner, oturum düşmesi, sayaç uzlaştırma, migration 018–021, yük testi | ✅ (2026-10-25) |

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

## Faz 2 — Ölçek & dayanıklılık ✅

- [x] Cursor (keyset) sayfalama + sonsuz kaydırma: feed, yorumlar, arama, mesajlar, takipçiler, bookmark'lar. Liste sonundaki `LoadMoreFooter` göründükçe sonraki sayfayı ister (sohbette yukarı kaydırınca eski mesajlar); yorumlarda "Daha fazla göster" butonu. Silme ve profil etkileşimi yüklenen sayfaları korur (tek öğe güncellenir). Sohbet listesi sayfasız. Ortak takipçiler migration 018 `get_mutual_followers` RPC'siyle DB'de kesişimden (ilk 3 kişi + toplam; canlıda, anon erişimi kapalı, cihazda doğrulandı). _(2026-10-25; testli, tüm listeler cihazda doğrulandı)_ — `DATA-12`
- [x] Görsel sıkıştırma: picker uzun kenarı 2048px'e indirir, yükleme anında `compressToWebp` (`core/utils/image_compress.dart`, `flutter_image_compress`) WebP q80'e çevirir ve EXIF/konumu atar; kodlanamazsa orijinal yüklenir. Migration 019: `post-images` ve `avatars` için 2MB sunucu limiti (canlıda). _(2026-10-25; testli, cihazda doğrulandı: Storage'da WebP, boyut ~yarıya indi, exiftool: EXIF yok)_
- [x] `post-images` private (migration 020): okuma yalnızca oturumlu kullanıcı; repository sayfadaki tüm görselleri tek `createSignedUrlsResult` isteğiyle 1 günlük imzalar, imzalanamayan (silinmiş) dosya atlanır; `CachedNetworkImage` önbelleği dosya yoluna bağlı (token değişse de yeniden indirmez). _(2026-10-25; testli, canlıda: public endpoint "Bucket not found" dönüyor; cihazda doğrulanmadı)_ — `SEC-9`
  - **Bilinen sınır:** 020'den önce açık URL'si çekilmiş 5 dosya Supabase Smart CDN'de (Cloudflare) önbellekte kaldı; eski `/object/public/…` linkleri `cf-cache-status: HIT` ile hâlâ açılıyor. Bucket'ı private yapmak, dosyayı taşımak, silip yeniden yüklemek bu önbelleği temizlemedi (2026-10-25, 3+ dk izlendi). Yeni yüklemeler etkilenmez. Bu 5 dosya test verisi; kabul edildi. Gerçek veride aynı durum olursa Supabase desteğinden purge istenir. Eski uygulama sürümünde yeni yüklenen görsellerin açılmadığı cihazda doğrulandı (2026-10-25).
- [x] Tutarlı hata yönetimi: feed, arama, bookmark, takip, görüntülenme ve kayıt/oturum metotları da `guardSupabase` ile sarıldı; "oturum yok" artık `AuthRequiredFailure`. `23505` → `ConflictFailure` (kayıttaki kullanıcı adı yeniden denemesi buna bağlı), `StorageException` durum koduna göre (413 → `ValidationFailure`, 401/403/404). Kapsam dışı: `sendOtp`/`verifyOtp` (giriş ekranının kendi mesajları var, AUTH-10) ve realtime stream'ler. _(2026-10-25; testli)_
- [x] Offline banner + yeniden deneme: `connectivity_plus` ile `isOnlineProvider`; çevrimdışıyken tüm ekranların üstünde şerit (`OfflineBanner`, `MaterialApp.builder`). Bağlantı geri gelince sohbetler, açık sohbet ve bildirimler yeniden çekilir (realtime kopukken kaçan olaylar), feed hatadaysa kendiliğinden yeniden dener. Post detayı ve düzenleme hata ekranına "Tekrar Dene" eklendi; diğer listelerde zaten vardı. Bilinen sınır: Wi-Fi var ama internet yoksa şerit çıkmaz, o durumda ekranların hata + Tekrar Dene akışı devrede. _(2026-10-25; testli, cihazda şerit doğrulandı; yeniden bağlanınca tazeleme cihazda denenmedi)_
- [x] Oturum düşmesi: `AuthRepository.signedOut` (`onAuthStateChange` → `signedOut`) dinlenir, auth state null olur; router login'e yönlendirir, kullanıcıya özel provider'lar temizlenir. Bilinen sınır: kayıt ekranındayken (profil yok) oturum düşerse kullanıcı bir sonraki gezinmede login'e gider. _(2026-10-25; testli, cihazda doğrulanmadı)_ — `AUTH-5`
- [x] Sayaç uzlaştırma: migration 021 `reconcile_counters()` (SECURITY DEFINER, istemciye kapalı) tüm sayaçları kaynak tablolardan yeniden sayar, yalnızca farklı satırları düzeltir ve düzeltilen satır sayılarını jsonb döner; SQL Editor'dan `select public.reconcile_counters();` ile çalıştırılır (zamanlama yok, pg_cron gerekirse sonra). `>= 0` CHECK'leri canlıda 001'den beri zaten varmış (AUDIT tespiti hatalıydı); 021'in eklediği `*_nonneg` CHECK'leri tekrar, zararsız. Trigger'lardaki `GREATEST(…,0)` kaldı (sapmada unlike hata vermesin). _(2026-10-25; canlıda, sapma 0 satır, smoke 14 geçti)_ — `DATA-18`
- [x] `searchUsers` oturumsuzken kendini dışlama filtresini atlar — `DATA-20`

**Bitti tanımı:** Seed ile 1.000+ post ve 200+ mesaj varken feed ve chat akıcı kayıyor; uçak modunda uygulama çökmüyor, anlamlı bir mesaj gösteriyor.

**Yük testi (2026-10-25):** `supabase/scripts/load_test_seed.sql` canlı dev projesine uygulandı (1.000 post + 200 mesaj, hepsi `[seed]` önekli; geri almak için `load_test_cleanup.sql`). `EXPLAIN ANALYZE` (authenticated, RLS açık): 30. feed sayfası 0,57 ms, sohbet sayfası 0,39 ms, ikisi de indeksli. Feed planında imleç `or`'u indeks koşulu olmadığı için derin sayfa baştan taranıyordu (601 satır atlandı); `keyset.dart` artık `created_at` sınırını da gönderiyor, 0,23 ms / 1 satır. Cihazda feed ve sohbet kaydırma ile uçak modu doğrulandı.

**Durum (2026-10-25):** Faz 2 kapandı. `flutter analyze` hatasız, `flutter test` 257/257, migration 001–021 local = remote, smoke 14 geçti; seed verisiyle feed ve sohbet cihazda akıcı kayıyor, uçak modunda uygulama çökmüyor ve şerit + Tekrar Dene görünüyor.

---

## Faz 3 — UX cilası & yerelleştirme 🟡

- [x] Sabit metinler ARB'ye taşındı (~130 yeni anahtar, TR+EN). Enum adları `displayName(context)` extension'ında (`user_title_ui`, `dental_branch_ui`), modelde metin kalmadı. `getErrorMessage(l10n, e)`; context'i olmayan controller'lar `l10nProvider` kullanır. Arama ekranlarındaki ham `ValidationFailure.message` gösterimi kaldırıldı. Göreli zaman ARB'den, 30+ gün tarihi `intl` ile. `test/core/no_hardcoded_text_test.dart` Türkçe karakterli sabitleri yakalar. Metin değişiklikleri: tema seçenekleri "Açık/Koyu/Sistem Varsayılanı", kullanıcı arama alanı "Ara", ortak takipçi satırında kalın vurgu yok. _(2026-10-25; cihazda bakılmadı)_ — `UX-12`
- [x] Boş, hata ve yenileme durumları: sohbet listesine `DentLinkEmptyState`; bildirimler, sohbetler, takipçi/takip edilen ve profil gönderi sekmelerine çekerek yenileme (feed ve kaydedilenlerde zaten vardı). Yenilenirken mevcut liste ekranda kalır. _(2026-10-25; yalnızca UI bağlantısı, test yok)_ — `UX-7`
- [x] `PopScope`: ortak `UnsavedChangesScope` (vaka/soru oluşturma, post ve profil düzenleme). Gönderirken geri tuşu çalışmaz; form dokunulmuşsa onay diyaloğu (TR+EN); kaydedip çıkış etkilenmez. _(2026-10-25; testli)_ — `UX-2`
- [x] Uzunluk ve taşma: profil alanlarına sınır (ad 60, biyografi 300, üniversite/şehir/klinik 100; kayıt ve profil düzenleme, `ProfileLimits`), kayıtta da deneyim yalnızca rakam; migration 022 DB CHECK'leri (canlıda). Feed kartı başlığı `maxLines: 2`; post başlığındaki ve yorumdaki uzun isimler tek satır + ellipsis. Profil düzenleme: alanlar trim, deneyim yalnızca rakam (UX-10). _(2026-10-25; testli)_ — `UX-8`, `UX-9`, `UX-10`
- [x] Erişilebilirlik: yalnızca ikonlu butonlara tooltip (geri/temizle Material metinleri, gönder, devam, yeni mesaj, beğen, kaydet); detaydaki daire butonlar `IconButton`. 48dp dokunma alanı: beğeni/kaydet, yorum sayacı, aksiyon satırı, tıklanabilir avatarlar, alt menü "+", görsel kaldırma. Kontrast: yorum/cevap ipucu temadan, koyu tema `darkTextTertiary` ~5.6:1, alt menü etiketi 12px. `test/a11y_guidelines_test.dart` feed ve vaka detayında Flutter'ın `androidTapTargetGuideline` ve `labeledTapTargetGuideline` kontrollerini koşar. Görsel değişiklik: kartlarda aksiyon satırı 48px, avatar ve beğeni ikonu çevresinde boşluk arttı. _(2026-10-25; cihazda bakılmadı)_ — `UX-13`, `UX-14`, `UX-15`
- [x] Sabit renkler: marka teal'i (`0xFF13B9A5`, beyaz üzerinde ~2.5:1) yerine `colorScheme.primary`; koyu arka plan `AppColors.darkBackground`; kayıt diyaloğu tema rengini kullanır; branş renkleri `AppColors.branch*`. `lib/`'de `AppColors` ve tema dışında `Color(0x…)` kalmadı, `test/core/no_color_literals_test.dart` bunu korur. Görsel değişiklik: auth ve ayarlar ekranlarındaki teal, light temada daha koyu. _(2026-10-25; cihazda bakılmadı)_ — `UX-16`
- [x] Tema tercihi kalıcı: `SharedPreferences` `main`'de önceden yüklenir (açılışta tema yanıp sönmez). _(2026-10-25; testli)_ — `UX-11`
- [x] Bookmarks ekranı: beğeni çalışıyor (iyimser, feed ve aramaya yansır); kaydırma ve bookmark ikonu aynı akış: onaysız kaldırır, "Geri Al" postu eski sırasına koyar; kaldırma/geri alma feed ve aramadaki bookmark durumunu da günceller. _(2026-10-25; testli)_ — `BUG-24`
- [x] Kayıt başarı diyaloğu yarışı: kayıt sürerken ve diyalog açıkken `authRedirectHoldProvider` tutulur. Hazır avatarlar kaldırıldı (karar 2026-10-25); fotoğraf seçilmezse ikon gösterilir. _(2026-10-25; widget testli)_ — `BUG-21`, `AUTH-8`
- [x] Login küçük UX düzeltmeleri: geri sayım 60 sn (limiter ile aynı), yalnızca sunucunun reddettiği kod "Kod hatalı", ağ ve diğer hatalar `getErrorMessage` ile; dispose sonrası state yazılmaz. _(2026-10-25; testli)_ — `AUTH-10`
- [x] Domain katmanı kaldırıldı (karar 2026-10-25): `enums.dart` → `lib/data/models/`, `CommentEntity` → `CommentModel` (yazar `UserModel`, satır parse `CommentModel.fromRow`), `CommentRepository` arayüzü `lib/data/repositories/`; kullanılmayan `UserEntity`, `UserSummary`, `UserMapper`, `CommentMapper` silindi. Tek unvan varsayılanı `UserModel.fromJson`. — `DATA-19`
- [x] Ölü kod: ~~`FeedMode`~~ (DATA-12 ile kaldırıldı, `BUG-26` ✅); sohbet kullanıcı aramasında gerçek debounce: 300 ms içinde yeni harf gelirse önceki sorgu istek atmaz. _(2026-10-25; testli)_ — `BUG-22`

**Bitti tanımı:** Uygulama dili İngilizce'ye alınınca hiçbir Türkçe metin görünmüyor; en büyük yazı boyutunda ekranlar taşmıyor.

---

## Faz 4 — Moderasyon & hukuk 🛡️ (MVP için zorunlu)

- [x] İçerik ve kullanıcı **raporlama**: migration 023 `reports` (istemci yalnızca ekler, okuyamaz; aynı hedef bir kez, tekrarı sessizce yok sayılır). Post kartı menüsü sahibine Düzenle/Sil, başkasına Raporla/Engelle; post detayı, yorum, profil ve sohbette ⋮ menüsü. Rapor sheet'i: 6 sebep (hasta mahremiyeti dahil), 500 karakter not, gönderirken kilitli. _(2026-10-25; testli, **023 canlıya gönderilmedi**, cihazda denenmedi)_ — `UX-6`
- [x] Kullanıcı **engelleme**: migration 023 `blocks` + `is_blocked_between` (iki yönlü). `posts` ve `comments` SELECT policy'leri engelli çifti gizler, `send_message` 42501 döner, takip edilemez; engellenince iki yöndeki takip silinir. Eski mesaj geçmişi görünür kalır. İstemci yazarın postlarını feed'den, aramadan ve açık yorum listesinden yerelde çıkarır. Ayarlar → Engellenenler (iyimser engel kaldırma + rollback). Arkasında özellik olmayan "Gizlilik" satırı kaldırıldı. _(2026-10-25; testli, **023 canlıya gönderilmedi**)_ — `UX-6`
- [x] Moderasyon kuyruğu: Dashboard SQL Editor, sorgular [`SUPABASE.md`](./SUPABASE.md) §6. Smoke 15–17 eklendi.
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
| ~~Kayıtta hazır avatar seçeneği kalsın mı?~~ Kaldırıldı (2026-10-25) | Faz 3 ✅ |
| ~~Domain katmanı: tamamla mı, kaldır mı?~~ Kaldırıldı (2026-10-25) | Faz 3 ✅ |
| Doğrulama belgesi türü (diploma / TDB oda kaydı) | Faz 4 |
| İş ilanı ve pazar yeri: feed'de mi, ayrı sekmede mi? | Yayın sonrası |
