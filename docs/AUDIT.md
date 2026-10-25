# DentLink — Denetim Raporu (Audit)

> **Tarih:** 2026-10-13 · **Commit:** `0bf5d3f` (phase 3.7)
> **Kapsam:** Supabase migration'ları (001–011), tüm repository'ler, provider'lar, ekranlar, testler, Android/iOS yapılandırması.
> **Nasıl kullanılır:** Her bulgunun kalıcı bir ID'si var. [`ROADMAP.md`](./ROADMAP.md) bu ID'lere atıf yapar. Bir bulgu çözülünce **Durum** sütununu `✅` yap. Bulguyu silme ki geçmiş izlenebilsin.

**Önem:** 🔴 Kritik (veri sızıntısı, güvenlik, veri kaybı, ana akış kırık) · 🟠 Yüksek (görünür bug, yayın engeli) · 🟡 Orta · ⚪ Düşük

**Durum:** ⬜ açık · 🔧 devam ediyor · ✅ çözüldü

**Satır numaraları** denetim anındaki kod içindir. Kod değiştikçe kayabilir; dosya ve fonksiyon adını esas al.

---

## Başlangıç durumu (baseline)

| Kontrol | Sonuç |
|---|---|
| `flutter analyze` | 3 info (hata yok) |
| `flutter test` | 196 testten 3'ü kırık (bkz. `TEST-1`) |
| Uzak DB migration geçmişi | **Boş.** 001–011 Dashboard SQL Editor'dan elle uygulanmış; CLI hiçbirini bilmiyor (bkz. `DATA-1`). |
| Repository bağlantıları | Bildirimler hariç tümü Supabase. `NotificationRepository` hâlâ mock. |
| Canlı DB ↔ migration sapması | Canlıda `likes` üzerinde **hiç** unique kısıt yoktu (005 yarım uygulanmış); realtime yayını **boştu** (mesajlar canlı gelmiyordu); `follows`/`tags`/`post_tags` için UPDATE yetkisi yoktu (bkz. `DATA-21`). |

> **2026-10-13 güncellemesi:** Faz 0 düzeltmeleri uygulandı; `012_security_hardening.sql` canlıya push edildi, migration geçmişi onarıldı (001–012 local = remote). `flutter test`: 205/205 yeşil.

---

## SEC — Güvenlik (RLS, GRANT, Storage)

| ID | Önem | Konum | Sorun | Etki | Çözüm | Durum |
|---|---|---|---|---|---|---|
| SEC-1 | 🔴 | `003_rls_policies.sql:21-28`, `006:12` | `users_update_own`/`users_insert_own` yalnızca `id`'yi kontrol ediyor. UPDATE yetkisi tüm kolonlarda var. | Kullanıcı kendini `is_verified=true` yapabilir, takipçi ve post sayılarını uydurabilir. Sahte "doğrulanmış hekim" rozeti çıkar. | `REVOKE UPDATE, INSERT`. Yalnızca düzenlenebilir kolonlara kolon bazlı `GRANT` ver. | ✅ |
| SEC-2 | 🔴 | `003:241-243` | `messages_insert_own` yalnızca `sender_id`'yi kontrol ediyor. `conversation_id` ve `receiver_id` serbest. | Üçüncü bir kişi A–B sohbetine mesaj enjekte edebilir. Trigger da önizlemeyi ve okunmamış sayısını değiştirir. | Policy, konuşmanın `{sender,receiver}={user1,user2}` olduğunu doğrulasın; ideal olarak `send_message` RPC. | ✅ |
| SEC-3 | 🔴 | `003:263-265`, `006:45` | `notifications` INSERT için `WITH CHECK (true)`. | Herkes herkese sahte "X seni takip etti" bildirimi gönderebilir (spam, oltalama). | Policy'yi kaldır, INSERT'i revoke et. Bildirimleri yalnızca SECURITY DEFINER trigger'lar üretsin. | ✅ |
| SEC-4 | 🟠 | `003:44-47` | `posts_update_own` + tam UPDATE grant'ı. | Sahip kendi `like_count`, `view_count`, `comment_count` ve `is_solved` değerlerini yazabilir. | `GRANT UPDATE (title, content, branch)`. | ✅ |
| SEC-5 | 🟠 | `003:138-141` | `comments_update_own` tüm kolonlara açık. | Yorumcu kendi cevabını `is_best_answer=true` yapabilir, `like_count`'ı değiştirebilir, `post_id`'yi değiştirip yorumu başka posta taşıyabilir (sayaçlar kayar). | `GRANT UPDATE (content)`. | ✅ |
| SEC-6 | 🟠 | `003:17-19`; `supabase_post_repository.dart:29`, `supabase_follow_repository.dart:71,83`, `supabase_user_repository.dart:22,38` | `users` herkese tamamen okunabilir ve sorgular `users(*)` çekiyor. | Giriş yapmış her kullanıcı herkesin **e-posta ve telefonunu** görebilir (KVKK ihlali). | `email` ve `phone` için kolon SELECT'ini revoke et. Sorgularda kolonları açıkça listele. | ✅ |
| SEC-7 | 🟠 | `003:214-227` | `conversations` INSERT/UPDATE kullanıcıya açık. | Katılımcı `user1_id`/`user2_id`, önizleme ve okunmamış sayılarını değiştirebilir. Sırasız çift eklenirse `get_or_create_conversation` NULL döner ve uygulama çöker. | INSERT/UPDATE'i revoke et; RPC'ler ve trigger'lar yeterli. | ✅ |
| SEC-8 | 🟠 | `003:246-249`, `006:42` | Gönderen mesajın her kolonunu güncelleyebilir. | Mesaj sonradan değiştirilebilir, başka sohbete taşınabilir, `is_read` değiştirilebilir. | `GRANT UPDATE (deleted_at)` (soft delete). | ✅ |
| SEC-9 | 🟠 | `004:43` | `post-images` bucket'ı `public=true`. | Klinik hasta fotoğrafları URL'yi bilen herkese, oturum açmadan açık (KVKK). | Bucket'ı private yap, `createSignedUrl` kullan, DB'de path sakla. *(Faz 2)* | ✅ (020) |
| SEC-10 | 🟠 | `supabase_user_repository.dart:105-120`, `supabase_auth_repository.dart:258-262` | `avatars` bucket'ı ve policy'leri hiçbir migration'da yok. | Bucket elle kurulmuş; policy'ler bilinmiyor ve versiyon kontrolünde değil. | Migration'da bucket'ı ve `auth.uid()` klasör policy'lerini tanımla. | ✅ |
| SEC-11 | 🟡 | `005:19-22`, `supabase_post_repository.dart:475-482` | `tags_update_auth USING (true)`; upsert `name`'i de eziyor. | Herhangi bir kullanıcı herhangi bir etiketin adını değiştirebilir. | Update policy'sini kaldır; `upsert(ignoreDuplicates: true)`. | ✅ |
| SEC-12 | 🟡 | `supabase_auth_repository.dart:219-235` | `email`/`phone` istemciden geliyor ve UNIQUE. | Saldırgan, kurbanın e-postasını kendi satırına yazarak kurbanın kaydını engelleyebilir. | Trigger ile `auth.users`'tan doldur; istemci göndermesin. | ✅ |
| SEC-13 | ⚪ | `003:63-70` | Post sahibi `post_images.image_url`'e istediği harici URL'yi yazabilir. | Takip pikseli veya denetlenmemiş görsel eklenebilir. | Path sakla ve bucket önekini doğrula (create_post RPC). | ✅ |
| SEC-14 | ⚪ | `008`, `010`, `011` | SECURITY DEFINER fonksiyonlarda `search_path = public`. | Düşük risk (PG15+). | `SET search_path = ''` ve şema-nitelikli isimler. | ⬜ |
| SEC-15 | ⚪ | `lib/main.dart:14-15` | URL ve anon (publishable) key kodda sabit. | Anon key zaten açık olabilir, ama dev/prod ayrımı yapılamıyor. | `--dart-define-from-file` (Faz 5). | ⬜ |

---

## DATA — Veri bütünlüğü & backend mantığı

| ID | Önem | Konum | Sorun | Etki | Çözüm | Durum |
|---|---|---|---|---|---|---|
| DATA-1 | 🔴 | uzak DB | Migration geçmişi boş, SQL elle uygulanmış. | Hangi migration'ın canlıda olduğu bilinmiyor; `db push` hepsini yeniden çalıştırmaya çalışır. | `supabase migration repair --status applied 001..011`, ardından hep `db push`. | ✅ |
| DATA-2 | 🔴 | `005_faz_3_3_fixes.sql:31-32`; `supabase_post_repository.dart:285-294`, `supabase_comment_repository.dart:76-85` | `UNIQUE NULLS NOT DISTINCT (user_id, post_id)` ve `(user_id, comment_id)`: NULL'lar eşit sayılıyor. Kod 23505 hatasını "zaten beğenilmiş" diye yutuyor. | **Her kullanıcı ömründe yalnızca 1 post ve 1 yorum beğenebiliyor.** Sonraki beğeniler sessizce başarısız oluyor. | Constraint'leri düşür; partial unique index (`WHERE post_id IS NOT NULL`). | ✅ |
| DATA-3 | 🟠 | `lib/data/models/badge_model.dart:24` | `json['icon_url'] as String` okunuyor, ama kolonun adı `icon_name`. | Rozeti olan kullanıcının profili TypeError ile çöküyor. | `icon_name` oku. | ✅ |
| DATA-4 | 🟠 | `supabase_post_repository.dart:333-383, 455-491` | Post oluşturma 4 ayrı adımdan oluşuyor: post, görsel yükleme, `post_images`, etiketler. | Orta adımda hata olursa feed'de yarım post kalır, `posts_count` artar, yetim dosyalar oluşur. | Önce görselleri yükle, sonra tek `create_post` RPC; hata olursa yüklenenleri sil. *(Faz 1)* | ✅ |
| DATA-5 | 🟠 | migration'lar | `notifications`'a yazan **hiçbir trigger yok**. | Bildirim sistemi backend'de hiç çalışmıyor. | `likes`, `comments`, `follows`, `messages` ve `mark_best_answer` için AFTER INSERT trigger'ları. *(Faz 1)* | ✅ |
| DATA-6 | 🟡 | `005:6-16` | `increment_view_count` SECURITY INVOKER; RLS yalnızca sahibe izin veriyor. | Görüntülenme sayısı yalnızca sahip kendi postuna bakınca artıyor. | SECURITY DEFINER + `search_path`, `anon`'dan revoke. | ✅ |
| DATA-7 | 🟡 | `supabase_post_repository.dart:389-409` | `deletePost` önce dosyaları siliyor, sonra satırı. Etkilenen satır sayısı kontrol edilmiyor. | Silme başarısız olur ya da RLS 0 satır döndürürse post kırık görsellerle kalır. | Önce satırı sil (`.select()` ile doğrula), sonra dosyaları. | ✅ |
| DATA-8 | 🟡 | `supabase_user_repository.dart:105-109` | Eski avatar yeni avatar yüklenmeden siliniyor. | Yükleme başarısız olursa `avatar_url` silinmiş bir dosyayı gösterir. | Önce yükle, satırı güncelle, sonra eskiyi sil. | ✅ |
| DATA-9 | 🟡 | `supabase_post_repository.dart` (`_slugify`) | Harf/rakam içermeyen etiketler için slug `''`; "İmplant" ve "implant" aynı slug'a düşüyor ve son yazan kazanıyor. | Etiketler birbirine karışıyor. | Boş slug'ı atla; `ignoreDuplicates`. | ✅ |
| DATA-10 | 🟡 | `supabase_message_repository.dart:60, 90-96` | `last_message_at` NULL olanlar en üstte sıralanıyor. Konuşma oluşturma ve mesaj gönderme ayrı istekler. | Mesaj gönderilemezse boş sohbet listenin tepesinde kalır. | `nullsFirst: false`; tek bir `send_message` RPC. *(Faz 1)* | ✅ |
| DATA-11 | 🟡 | migration'lar, `lib/providers/message_provider.dart` | `supabase_realtime` yayınına tablo ekleyen migration yok. | Realtime yalnızca Dashboard'dan elle açıldıysa çalışır. | `ALTER PUBLICATION supabase_realtime ADD TABLE messages, conversations`. | ✅ |
| DATA-12 | 🟡 | `supabase_post_repository.dart:143-231`, `supabase_follow_repository.dart:71-91`, `supabase_message_repository.dart:52-73` | Sayfalama yok. Feed'de `limit(50)` var; takipçi, sohbet ve mesaj listeleri limitsiz; bookmark sorgusunda URL'de sınırsız `inFilter`. | 50. posttan sonrası görünmez, büyük listeler yavaşlar. | Cursor (keyset) sayfalama. *(Faz 2)* **Çözüm:** `(created_at, id)` imleci (`core/utils/paging.dart`, `data/repositories/keyset.dart`), sayfa 20; feed, profil, arama, bookmark (sayfa başına `inFilter` en fazla 20 id), yorum, mesaj, takipçi/takip edilen. Sohbet listesi bilerek sayfasız (sohbet ekranı ve okunmamış rozeti tüm listeye bakar); ortak takipçiler migration 018 `get_mutual_followers` RPC'siyle (DB'de kesişim, ilk 3 + toplam). | ✅ |
| DATA-13 | ⚪ | `003`, `004:50-73`, `005`; `001:102-110` | Migration'lar tekrar çalıştırılamıyor (çıplak `CREATE POLICY`). `EXCEPTION WHEN OTHERS THEN NULL` hataları gizliyor. | Yeni ortam kurulumu kırılgan. | Yeni migration'larda `DROP ... IF EXISTS` kalıbı. | ⬜ |
| DATA-14 | ⚪ | `011:6-7` ve `001:272-273` | Aynı unique index iki kez tanımlı. | Her insert iki kez index yazıyor. | Birini düşür. | ✅ |
| DATA-15 | ⚪ | `004:127-203` | `mark_messages_read` (ölü, işlevsiz) ve 011'in ezdiği eski fonksiyon. | Kafa karışıklığı. | Düşür. | ✅ |
| DATA-16 | ⚪ | `008:12-42` | `mark_best_answer` postun `question` tipinde olduğunu kontrol etmiyor; işaret geri alınamıyor; en iyi cevap silinince `is_solved` true kalıyor. | Tutarsız soru durumu. | Tip kontrolü, unmark ve silme trigger'ı. *(Faz 1)* | ✅ |
| DATA-17 | ⚪ | şema | İçerik alanlarında uzunluk ve boşluk CHECK'i yok. | Boş veya devasa içerik yazılabilir. | `CHECK (char_length(...) BETWEEN 1 AND N)`. *(Faz 1)* | ✅ |
| DATA-18 | ⚪ | `001:103-105` | Sayaç kolonlarında `>= 0` CHECK'i yok; `GREATEST(…,0)` sapmayı gizliyor. | Sayaçlar zamanla kayabilir. | Migration 021: `reconcile_counters()`. CHECK'ler canlıda zaten vardı (tespit hatalı). | ✅ |
| DATA-19 | ⚪ | `lib/domain/**`, `user_mapper.dart:7,48`, `user_model.dart:75` | Yarım kalmış domain katmanı (yalnızca yorumlar kullanıyor). `UserMapper` kullanılmıyor. Varsayılan unvanlar tutarsız (`disHekimi` / `unknown`). | Kafa karışıklığı. | Ya tamamla ya da kaldır (karar: Faz 3). | ✅ |
| DATA-21 | 🔴 | `supabase_follow_repository.dart` (followUser), `supabase_post_repository.dart` (`_upsertAndLinkTags`) | `.upsert()` (ON CONFLICT DO UPDATE) UPDATE yetkisi ister; canlıda `follows`, `tags`, `post_tags` için UPDATE yetkisi yok. | **Takip etme ve etiketli post oluşturma canlıda 42501 ile başarısız oluyordu** (DB'de 0 follow, 0 tag vardı). | follows: `insert` + 23505 yut; tags: `upsert(ignoreDuplicates)` + slug ile select; post_tags: toplu `insert`. | ✅ |
| DATA-20 | ⚪ | `supabase_user_repository.dart:34,39` | `searchUsers` oturum yokken `neq('id', '')` ile uuid cast hatası veriyor. | Oturum açılmadan arama yapılırsa hata. | Oturum yoksa filtreyi atla. | ✅ |

---

## AUTH — Kimlik doğrulama & oturum durumu

| ID | Önem | Konum | Sorun | Etki | Çözüm | Durum |
|---|---|---|---|---|---|---|
| AUTH-1 | 🔴 | `supabase_auth_repository.dart:189-191`, `app_router.dart:84-87` | `getProfile` içinde `catch (_) { return null; }`: ağ hatası "profil yok" sayılıyor. | Mevcut kullanıcı kayıt ekranına atılıyor; kaydı tamamlarsa upsert gerçek profilini (`username`, `full_name`, `created_at`) eziyor. | Yalnızca `maybeSingle()==null` ise null dön, diğer hatalarda fırlat. Router hata durumunda yeniden dene ekranı göstersin. | ✅ |
| AUTH-2 | 🔴 | `auth_provider.dart:79-82`, `following_provider.dart:60`, `message_provider.dart:67,101` | Çıkışta kullanıcıya özel provider'lar temizlenmiyor. | Aynı cihazda giriş yapan sonraki kullanıcı, öncekinin takip durumunu ve sohbetlerini görebilir; realtime kanalı eski kullanıcıya filtreli kalır. | Çıkışta invalidate et; kullanıcıya özel provider'lar user id'yi `watch` etsin. | ✅ |
| AUTH-3 | 🟠 | `register_screen.dart:112`, `app_router.dart:86` | Kayıtta 0. adımda "Geri" `/login`'e gidiyor, redirect tekrar `/register`'a atıyor. | Kaydı yarım kalan kullanıcı sıkışıyor, başka hesaba geçemiyor. | 0. adımda geri = `signOut()` + `/login`. | ✅ |
| AUTH-4 | 🟠 | `lib/core/utils/string_utils.dart:11-24` | ASCII olmayan karakterler Türkçe eşlemeden önce siliniyor; ek yalnızca 10.000 olasılık. | "Çağrı Şen" → `ar_en_1234`. Çakışmada kayıt ham hatayla başarısız oluyor. | Önce Türkçe eşleme; 23505 alınırsa yeni ekle yeniden dene. | ✅ |
| AUTH-5 | 🟠 | `lib/` genelinde | `onAuthStateChange` dinlenmiyor. | Refresh token iptal edilir veya süresi dolarsa kullanıcı, istekleri başarısız olan ekranlarda kalıyor. | Router'da dinle; `signedOut` olunca auth'u null yap. *(Faz 2)* | ✅ |
| AUTH-6 | 🟡 | `supabase_auth_repository.dart:231,235` | `completeRegistration` `created_at` gönderiyor. | Yeniden kayıtta oluşturma tarihi eziliyor. | Gönderme; DB default'u kullansın. | ✅ |
| AUTH-7 | 🟡 | `supabase_auth_repository.dart:109,116,37` | `verifyOtp` e-postayı küçük harfe çevirmiyor; e-posta olmayan her girdi telefon sayılıyor; TLD regex'i `{2,4}`. | `.health`, `.dental` gibi uzantılar reddediliyor; büyük harfli e-posta doğrulanamıyor. | `_normalizeDestination`'ı yeniden kullan; `{2,}`. | ✅ |
| AUTH-8 | 🟡 | `register_controller.dart:116`, `register_screen.dart:44` | Hazır avatar seçimi (`selectedAvatarIndex`) kaydedilmiyor; 4 Unsplash URL'sinden 3'ü aynı. | Kullanıcının seçimi kayboluyor. | Hazır avatarları kaldır ya da URL'yi kaydet. | ✅ |
| AUTH-9 | 🟡 | `supabase/config.toml:160-164,260` | `site_url=127.0.0.1`; e-posta şablonu repoda değil. | Hosted şablon `{{ .Token }}` yerine magic link gönderirse e-postayla giriş kırılır. | `config.toml`'u commit et; şablonun OTP kodu içerdiğini doğrula. | ⬜ |
| AUTH-10 | ⚪ | `login_controller.dart:55,90,125,132-136` | Geri sayım 59 sn, limiter 60 sn; ağ hatası "Kod hatalı" diye gösteriliyor; ham `Exception:` metni; dispose sonrası state yazımı. | Küçük UX ve kararlılık sorunları. | 60 sn; hata eşleyici; `ref.mounted` kontrolü. | ✅ |
| AUTH-11 | ⚪ | `app_router.dart:53` | Oturum varken `initialLocation: '/login'`, profil yüklenirken login formu bir an görünüyor. | Göz kırpma. | Splash/yükleme ekranı. | ⬜ |

---

## BUG — Fonksiyonel buglar (UI + state)

| ID | Önem | Konum | Sorun | Etki | Çözüm | Durum |
|---|---|---|---|---|---|---|
| BUG-1 | 🔴 | `post_header.dart:163`, `post_detail_author_info.dart:390`, `comment_card.dart:206`, `search_results.dart:196`, `followers_screen.dart:140` | `UserAvatar`/`UserTile` için `onTap` verilmemiş. | Feed, detay, yorum, arama veya takipçi listesinden **başka bir kullanıcının profiline gidilemiyor**. | `onTap: () => context.push('/profile/$id')`. | ✅ |
| BUG-2 | 🔴 | `profile_header.dart:61`, `user_provider.dart:34` | Başkasının profilinde buton yok. | Profilden **takip edilemiyor, mesaj atılamıyor**. | Takip et + Mesaj butonları. | ✅ |
| BUG-3 | 🔴 | `case_card.dart:48`, `question_card.dart:47` | Post menüsü (düzenle/sil/raporla) boş TODO. | Kullanıcı kendi postunu **silemiyor**. | Sahibine onaylı "Sil"; diğer seçenekleri hazır olana kadar gizle. | ✅ |
| BUG-4 | 🔴 | `create_case_screen.dart:71`, `create_question_screen.dart:47` | Gönderimden sonra yalnızca `pop()`; provider'lar yenilenmiyor. | Yeni post **feed'de ve profilde görünmüyor**; post sayısı güncellenmiyor. | `feedProvider`, `userPostsProvider(uid)`, `authProvider` invalidate. | ✅ |
| BUG-5 | 🔴 | `profile_posts_tab.dart:40-43` | Profil sekmesindeki like/bookmark `feedProvider.notifier`'ı çağırıyor; feed yüklü değilse erken dönüyor. | Profil sekmesinde beğeni ve kaydetme çalışmıyor. | Repository'yi çağır + `userPostsProvider`'ı invalidate et. | ✅ |
| BUG-6 | 🔴 | `search_provider.dart:72-84` (~370) | `Future.wait` try/catch'siz; istek sırası korunmuyor. | Herhangi bir hatada arama **sonsuza kadar yükleniyor**; eski sorgunun sonucu yenisini ezebiliyor. | try/catch → `AsyncError`; `query != state.query` ise sonucu at. | ✅ |
| BUG-7 | 🔴 | `bookmark_provider.dart:35`, `bookmarks_screen.dart:75` | Kaydırınca önce ağ isteği bekleniyor, sonra liste güncelleniyor. | "Dismissed Dismissible still in tree" assertion hatası; ağ hatası yakalanmıyor. | Önce yerel listeden çıkar, sonra API; hata olursa geri al. | ✅ |
| BUG-8 | 🟠 | `case_detail_screen.dart:30,244-259` | Takip butonu yerel `_isFollowing` ile çalışıyor, backend'e gitmiyor. | Takip etmiş gibi görünüyor ama etmiyor. | `isFollowingProvider` + `followingStateProvider.toggleFollow`. | ✅ |
| BUG-9 | 🟠 | `case_detail_screen.dart:32,95-97` | Görselsiz vakada Google'dan harici bir röntgen görseli gösteriliyor. | **Yanıltıcı tıbbi içerik**: vakaya ait olmayan bir görsel. | Fallback'i kaldır. | ✅ |
| BUG-10 | 🟠 | `case_detail_screen.dart:94,510`, `question_detail_screen.dart:87,369` | Sert `as CasePostModel` cast'i; loading/error durumlarında AppBar ve geri butonu yok; deep link'ten açılınca `pop()` fırlatıyor. | Yanlış tipte linkle çökme; hata ekranında kullanıcı sıkışıyor. | Tip kontrolü, AppBar, `canPop() ? pop() : go('/feed')`. | ✅ |
| BUG-11 | 🟠 | `case_detail_screen.dart:342` | Paylaş butonu "Bağlantı kopyalandı!" diyor ama hiçbir şey kopyalamıyor. | Sahte geri bildirim. | Kaldır ya da `Clipboard`/`share_plus`. *(Faz 1)* | ✅ |
| BUG-12 | 🟠 | `feed_provider.dart:39-76`, `search_provider.dart:106-142`, `post_provider.dart:16-36`, `post_media.dart:193` | Like/bookmark iyimser değil, in-flight guard'ı yok, hata yakalanmıyor. | Çift dokunuşta iki istek gidiyor; buton geç tepki veriyor; detaydaki her beğeni tüm feed'i yeniden yüklüyor. | `comment_provider.dart:46`'daki `_pending` + iyimser + rollback kalıbı. *(Faz 1)* | ✅ |
| BUG-13 | 🟠 | `case_detail_screen.dart:49`, `question_detail_screen.dart:42` | Yorum gönderiminde `_isSubmitting` yok; yorum sayısı güncellenmiyor. | Çift yorum; sayaç eski kalıyor. | Submitting flag + `postDetailProvider` invalidate. *(Faz 1)* | ✅ |
| BUG-14 | 🟠 | `search_provider.dart:35-36,333`, `filter_chips.dart:39,61,73,87` | `copyWith` `??` kullanıyor; `PopupMenuItem(value: null)` `onSelected`'ı tetiklemiyor. | Arama filtreleri **temizlenemiyor**; "Tümü" seçeneği çalışmıyor. | `ValueGetter` copyWith; null yerine sentinel değer. | ✅ |
| BUG-15 | 🟠 | `image_picker_grid.dart:222-254` | İzin reddine try/catch yok; `mounted` kontrolü yok; limit aşılınca görseller sessizce atılıyor. | Kullanıcı neden olmadığını anlamıyor. | try/catch + ayarlara yönlendiren snackbar; `limit:`. *(Faz 1)* | ✅ |
| BUG-16 | 🟠 | `edit_profile_screen.dart:150`, `edit_profile_controller.dart:37,49` | Avatar değiştirme butonu boş ("Mock image picker"); user id null olsa da "başarılı" dönüyor; deneyim alanı sayı değilse sessizce null oluyor. | Avatar değiştirilemiyor. | `ImagePicker` bağla; hata fırlat; sayı doğrulama. *(Faz 1)* | ✅ |
| BUG-17 | 🟠 | `chat_screen.dart:137,199`, `conversations_screen.dart:60`, `app_router.dart:169` | Ek (+) ve ⋮ menüleri boş; deep link'ten açılınca isim "Kullanıcı" görünüyor. | Ölü butonlar. | Gizle; karşı kullanıcıyı id ile çek. *(Faz 1)* | ✅ |
| BUG-18 | 🟠 | `message_provider.dart:24,40,97,115-130,165` | Her realtime olayında `invalidateSelf()` çağrılıyor (abonelik ve tüm mesajlar yeniden yükleniyor); `unsubscribe` var ama `removeChannel` yok; konuşma kanalında sunucu filtresi yok. | Arada gelen olaylar kaçıyor, kanallar sızıyor, gereksiz trafik oluşuyor. | `payload.newRecord`'u state'e ekle; `removeChannel`; filtre. *(Faz 1)* | ✅ |
| BUG-19 | 🟡 | `mutual_followers_widget.dart:14` | Profilin takipçilerini "ortak takipçi" diye gösteriyor. | Yanlış bilgi (kendi profilinde bile). | Gerçek kesişim sorgusu ya da widget'ı kaldır. | ✅ |
| BUG-20 | 🟡 | `followers_screen.dart:142` | Kullanıcının kendi satırında takip butonu görünüyor. | Kendini takip etmeye çalışabiliyor. | `user.id == me` ise butonu gizle. | ✅ |
| BUG-21 | 🟡 | `register_screen.dart:122-147` | Başarı diyaloğu ile router redirect'i yarışıyor. | Diyalog görünmeyebilir. | `authRedirectHoldProvider`'ı OTP akışındaki gibi kullan. | ✅ |
| BUG-22 | 🟡 | `user_search_delegate.dart:254` | "Debounce" aslında gecikme: her tuşta istek gidiyor. | Gereksiz istekler. | `Timer` iptal kalıbı. | ✅ |
| BUG-23 | 🟡 | `notifications_screen.dart:42,134` | `markRead` await edilmiyor, hatası yakalanmıyor; hata durumu `postLoadError` metnini kullanıyor. | Sessiz hatalar. | *(Faz 1, gerçek repo ile)* | ✅ |
| BUG-24 | 🟡 | `bookmarks_screen.dart:94` | Kaydedilenlerdeki like butonu animasyon oynatıyor ama hiçbir şey yapmıyor; bookmark ikonu onaysız ve geri almasız siliyor. | Tutarsız davranış. | Bağla; undo snackbar. | ✅ |
| BUG-25 | 🟡 | `tag_input.dart:36`, `post_body.dart:16` | Onaylanmamış etiket gönderimde kayboluyor; etiket limiti yok; `#` ve boşluk temizlenmiyor; etiket tıklanabilir görünüyor ama `onTagTap` null. | Veri kaybı ve yanıltıcı UI. | Gönderimde bekleyen etiketi ekle, normalize et, limit koy. | ✅ |
| BUG-26 | ⚪ | `feed_provider.dart:28` | `FeedMode`/`switchMode` kullanılmıyor; `getFeed`'in `chronological` parametresi yok sayılıyor. | Ölü kod. | Kaldır (algoritmik feed yayın sonrası). **Çözüm:** DATA-12 ile kaldırıldı. | ✅ |
| BUG-27 | 🟠 | `supabase_post_repository.dart` like/bookmark, `post_provider.dart`, `feed_provider.dart`, `search_provider.dart` | Başka cihazda silinmiş postu beğenmek/kaydetmek: FK (23503) ve `.single()` (PGRST116) hataları `guardSupabase`'siz ve yakalanmadan UI'a çıkıyor. _(2026-10-20 cihazda bulundu)_ | Uygulama duruyor (yakalanmamış istisna). | Metotlar `guardSupabase` → `NotFoundFailure`; detay "bulunamadı" durumuna geçer, feed/arama postu listeden düşürür, UI `runOrShowError` ile SnackBar gösterir. | ✅ |
| BUG-28 | 🟠 | `main_shell.dart`, `feed_list.dart`, `search_results.dart`, `profile_posts_tab.dart` | Yüzen alt menü listelerin son öğesini örtüyor; liste kısaysa kaydırılamadığı için menü gizlenmiyor. _(2026-10-21 cihazda bulundu)_ | Tek sonuçlu aramada postun beğeni butonuna basılamıyor. | Kabuk bar yüksekliğini (`BottomBarScope.barHeight`) `MediaQuery` alt boşluğu olarak verir; sekme listeleri bunu alt padding'e ekler. | ✅ |

---

## UX — Eksik durumlar, cila, erişilebilirlik, l10n

| ID | Önem | Konum | Sorun | Çözüm | Durum |
|---|---|---|---|---|---|
| UX-1 | 🟠 | `app_bottom_nav_bar.dart:70`, `feed_screen_app_bar.dart:252` | Okunmamış mesaj ve bildirim rozeti yok (provider'lar var ama izlenmiyor). | `Badge` widget'ı. *(Faz 1)* | ✅ |
| UX-2 | 🟠 | create/edit ekranları | `PopScope` yok; dolu form ve yükleme sırasında geri basılınca veri kayboluyor, retry'da duplicate oluşabiliyor. | `PopScope(canPop: !loading && !dirty)` + onay diyaloğu. *(Faz 3)* | ✅ |
| UX-3 | 🟠 | `create_case_screen.dart:65`, `create_question_screen.dart:41`, `edit_profile_screen.dart:73`, `case_detail_screen.dart:58,517`, `question_detail_screen.dart:51,376`, `register_screen.dart:153`, `profile_posts_tab.dart:51` | Ham `Exception: ...` metni kullanıcıya gösteriliyor. | `getErrorMessage(e)` (`lib/shared/utils/error_messages.dart`). | ✅ |
| UX-4 | 🟠 | `settings_screen.dart:303-332` | Bildirim toggle'ları `value: true` ile sabit; `onToggle` boş. | Gizle ya da bağla. *(Faz 1)* | ✅ |
| UX-5 | 🟠 | `settings_screen.dart:353-404` | Gizlilik, Engellenenler, Koşullar ve Politika `enabled:false`; **hesap silme yok** (mağaza zorunluluğu); sürüm sabit "v0.1.0 (Demo)"; çıkışta onay yok. | Faz 4 (hukuk) + `package_info_plus` + onay diyaloğu. | ⬜ |
| UX-6 | 🟠 | menüler, profil, chat | Raporlama ve engelleme yok. | Faz 4. | ⬜ |
| UX-7 | 🟡 | `profile_posts_tab.dart` ve diğerleri | Boş durum yok; profil, bildirim, sohbet ve takipçi ekranlarında pull-to-refresh yok. | `EmptyState` widget'ı + `RefreshIndicator`. *(Faz 3)* | ✅ |
| UX-8 | 🟡 | tüm girişler; `post_body.dart:35` | `maxLength` yok; feed kartındaki başlıkta `maxLines` yok. | Başlık 150, gövde 5000, yorum 2000 karakter; kartta `maxLines: 2`. *(Faz 3)* | ✅ |
| UX-9 | 🟡 | `comment_card.dart:216-233`, `post_header.dart:173` | Uzun isimler taşıyor. | `Expanded` + ellipsis. *(Faz 3)* | ✅ |
| UX-10 | 🟡 | `edit_profile_screen.dart:166` | İsim doğrulaması `trim` yapmıyor; deneyim alanında sayı filtresi yok. | `trim()`, `digitsOnly`. | ✅ |
| UX-11 | 🟡 | `theme_provider.dart:19` | Tema tercihi kaydedilmiyor (dokümanda kaydediliyor yazıyordu). | `SharedPreferences`. *(Faz 3)* | ✅ |
| UX-12 | 🟡 | `lib/features/**`, `enums.dart:18,80` | l10n yalnızca 89 dosyanın 11'inde kullanılıyor; ~155 sabit Türkçe metin var; enum `displayName` değerleri yalnızca Türkçe. TR ve EN arb anahtarları eşit. | Ekran ekran ARB'ye taşı. *(Faz 3)* | ⬜ |
| UX-13 | ⚪ | `app_bottom_nav_bar.dart:163`, detail geri/bookmark daireleri, gönder butonları vb. | Yalnızca ikon içeren butonlarda tooltip ve semantics yok. | `tooltip:` / `Semantics`. *(Faz 3)* | ✅ |
| UX-14 | ⚪ | `image_picker_grid.dart:364` (~22px), create butonu (~38px), `animated_action_button.dart:76` | Dokunma alanları küçük. | Minimum 48×48. *(Faz 3)* | ✅ |
| UX-15 | ⚪ | `case_detail_screen.dart:484`, `question_detail_screen.dart:343`; `darkTextTertiary` | Düşük kontrast (2.7:1, 3.6:1); alt menü etiketleri 10px. | 4.5:1 hedefi. *(Faz 3)* | ✅ |
| UX-16 | ⚪ | birçok ekran | `Color(0xFF11211F)` ve `Color(0xFF13B9A5)` sabit yazılmış, tema kullanılmıyor. | `Theme.of(context).colorScheme`. *(Faz 3)* | ✅ |
| UX-17 | ⚪ | — | Oturum açıkken önce login formu görünüyor (bkz. AUTH-11); splash yok. | Faz 5. | ⬜ |

---

## REL — Yayın hazırlığı

| ID | Önem | Konum | Sorun | Çözüm | Durum |
|---|---|---|---|---|---|
| REL-1 | 🟠 | `ios/Runner/Info.plist` | `NSCameraUsageDescription` ve `NSPhotoLibraryUsageDescription` yok, iOS'ta kamera/galeri açılınca **crash**. | İki anahtarı Türkçe açıklamayla ekle. | ✅ |
| REL-2 | 🟠 | `android/app/build.gradle.kts:32` | Release build debug key ile imzalanıyor; Play Store reddeder. | `key.properties` (git dışı) + release signingConfig. *(Faz 5)* | ⬜ |
| REL-3 | 🟡 | `pubspec.yaml`, `assets/fonts/*` | Font klasörleri boş, `fonts:` tanımı yok; uygulama sistem fontuna düşüyor. | Font dosyalarını ekle ve tanımla, ya da `google_fonts`. *(Faz 5)* | ⬜ |
| REL-4 | 🟡 | `AndroidManifest.xml:5`, `Info.plist:10`, `build.gradle.kts:19` | Etiket "dentlink"/"Dentlink"; launcher ikonu Flutter varsayılanı; `applicationId` şablon. | İsim, ikon ve id kararı. *(Faz 5)* | ⬜ |
| REL-5 | 🟡 | — | Crash raporlama yok (Sentry/Crashlytics). | *(Faz 5)* | ⬜ |
| REL-6 | 🟡 | — | Push bildirim yok (FCM). | *(Faz 5)* | ⬜ |
| REL-7 | ⚪ | `pubspec.yaml` | `flutter_riverpod` 2.x ve `go_router` 14.x bir major sürüm geride. | Yayın sonrası, ayrı bir PR'da yükselt. | ⬜ |

---

## TEST — Testler

| ID | Önem | Konum | Sorun | Çözüm | Durum |
|---|---|---|---|---|---|
| TEST-1 | 🟠 | `test/data/repositories/supabase_post_repository_test.dart`, `…_bookmark_test.dart`, `supabase_user_repository_test.dart` | 3 test kırık: mock'lar `upsert` bekliyor, kod `insert` kullanıyor; user update testi "0 satır" yolunu stub'lamıyor. | Testleri güncel koda uydur. | ✅ |
| TEST-2 | 🟠 | `integration_test/app_test.dart:33-40` | Yalnızca auth override ediliyor, diğer ekranlar `Supabase.instance` çağırıp fırlatıyor; assertion'lar `if (tester.any(...))` içinde. | Tüm repository'leri fake'le; koşullu assertion'ları kaldır. *(Faz 1)* | ✅ |
| TEST-3 | 🟡 | `test/` | Auth repository, redirect mantığı, provider'lar, comment/message/follow repository'leri ve widget'lar için hiç test yok. | Önce redirect matrisi ve sign-out temizliği testleri. | 🔧 |

---

## HYG — Hijyen & doküman

| ID | Önem | Konum | Sorun | Çözüm | Durum |
|---|---|---|---|---|---|
| HYG-1 | 🟡 | kök dizin | `fix_dimensions.py`, `fix_mock_datasource.py`, `fix_mock_datasource_args.py`: tek seferlik scriptler. | Sil. | ✅ |
| HYG-2 | 🟡 | `lib/data/datasources/mock_datasource.dart` (~1.2k satır), `mock_*_repository.dart` | Ölü mock kodu (yalnızca bildirim mock'u kullanılıyor). | Referansları kontrol et ve sil. | ✅ |
| HYG-3 | 🟡 | `android/build/reports/problems/problems-report.html` | Build çıktısı git'e girmiş. | `git rm --cached`. | ✅ |
| HYG-4 | 🟡 | `supabase/config.toml`, `supabase/.gitignore` | Takip edilmiyor. | Commit et. | ✅ |
| HYG-5 | ⚪ | `pubspec.yaml:38` | `mockito` normal bağımlılık; `flutter_svg` kullanılmıyor; yorumlar eski. | `mockito` → dev; `flutter_svg`'yi sil. | ✅ |
| HYG-6 | 🟡 | `progress.md`, `agents.md`, `README.md` | Dokümanlar gerçekle uyuşmuyor (3.7 ve 4.5 işaretsiz ama yapılmış; bildirimler "tam" yazıyor; `file:///home/user` linkleri var; README şablon). | `docs/` altında yeni yapı (bu denetimle birlikte). | ✅ |
