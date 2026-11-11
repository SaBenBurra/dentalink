# Dentigo Admin Paneli — Devir Notu (panel projesindeki ajan için)

> Bu dosya `dentlink` (mobil uygulama) reposunda durur ve iki proje için ortak kaynaktır. Panel projesinin `CLAUDE.md`'si bunu import eder. Panelle ilgili bir karar değişirse burayı güncelle.

## Ürün

Dentigo, diş hekimleri ve öğrenciler için mobil sosyal platform (Flutter + Supabase): vaka ve forum paylaşımı, 2. el ilan (Ticaret), takip, DM, bildirim, destek sohbeti. Ayrıntı: `../dentlink/agents.md`. Mobil uygulama `com.atlas.dentlink`; Supabase projesi `dentlink_backend`.

Panelin amacı: tüm sistemi tarayıcıdan yönetmek ve moderatör kullanıcılara belli yetkiler vermek.

## Kararlar (2026-11-09)

- **Web SPA:** React + Vite + TypeScript. `npm run build` → `dist/`, sahibinin kendi hostingine statik olarak yüklenir. Node sunucusu yok, Next.js yok. Hosting nginx ve ayarına erişim yok: `HashRouter` (adresler `/#/personel`), sunucuda yönlendirme gerekmez (2026-11-11).
- **Kütüphaneler:** `@supabase/supabase-js`, TanStack Query, react-router, Tailwind + shadcn/ui, TanStack Table. Gereksiz bağımlılık ekleme.
- **Dil:** arayüz yalnızca Türkçe (dahili araç, l10n yok).
- **Giriş kullanıcı adı + şifre, 2FA yok (2026-11-11).** Her personelin uygulamadaki hesabından ayrı bir panel hesabı var. Kullanıcı adı `<ad>@panel.dentigo.invalid` e-postasına çevrilir (`signInWithPassword`). `.invalid`e posta gitmez, bu yüzden şifre sıfırlama bağlantısını kimse alamaz; şifreyi yalnızca admin değiştirir. Panel hesabının `users` satırı vardır (staff, `support_messages.sender_id`, `staff_actions` ona bağlı) ama `onboarding_completed = false` kalır; arama (054), önerilenler ve popülerde görünmez. Destek cevabında kullanıcı bu satırdaki `full_name`i görür.
- **Panel yalnızca arayüzdür, yetki veritabanındadır.** Panel mobil uygulamayla aynı publishable (anon) key'i kullanır. `service_role` key panele asla girmez. Her yetki kontrolü RLS ve `SECURITY DEFINER` RPC'lerde yapılır; panelde bir hata olsa bile kullanıcı yetkisinin dışına çıkamaz. Arayüzdeki menü gizleme yalnızca kolaylıktır.
- `service_role` gerektiren işler (ör. `auth.users` ban) Edge Function'da yapılır; fonksiyon önce çağıranın yetkisini kontrol eder.

## Supabase

- URL: `https://lknvufbxekceevdblgmq.supabase.co` · ref `lknvufbxekceevdblgmq`
- Publishable key: `../dentlink/lib/main.dart` içindeki `publishableKey` (açık bilgi, `.env` içinde `VITE_` değişkeni olarak tut).
- Tipler: `supabase gen types typescript --project-id lknvufbxekceevdblgmq > src/types/database.ts`. Her migration'dan sonra yeniden üret, elle model yazma.
- **Şemanın asıl kaynağı:** `../dentlink/supabase/migrations/*.sql`. Kurallar: `../dentlink/docs/SUPABASE.md` (özellikle §1 migration akışı, §2 RLS/GRANT, §3 storage, §6 moderasyon, §11 destek ve personel). Önce bunları oku.

### Migration kuralı (önemli)

- Panel reposunda migration **yazılmaz**. Şema değişikliği `../dentlink/supabase/migrations/` altında, sıradaki numarayla (son: `054_…`) ve `SUPABASE.md` kurallarıyla yazılır.
- `supabase db push` canlı veritabanına uygular; kullanıcıya sormadan çalıştırma.
- Mobil uygulama sahada eski sürümlerle çalışıyor: mevcut RPC, kolon veya policy'yi kırma. Önce genişlet, sonra daralt (`../dentlink/docs/ROADMAP.md`, sürüm yönetimi maddesi).
- Bir migration yazınca `../dentlink/docs/SUPABASE.md` ve `../dentlink/docs/ROADMAP.md`'yi de güncelle.

## Mevcut altyapı

- **053 yetki:** `staff(user_id, role text → staff_roles)`, `staff_roles(name, permissions text[])`; hazır roller `support`, `moderator`, `admin` (hepsi). Kontrol `has_permission('<yetki>')`; `has_staff_role` 049 uyumluluğu için sarmalayıcı (049 policy'leri hâlâ onu kullanıyor, taşıma ayrı migration). Yönetim RPC'leri: `set_staff_role`, `remove_staff`, `save_staff_role`, `delete_staff_role` (`staff.manage`; son yönetici düşürülemez → `last admin`). `staff_actions` işlem kaydı (yalnızca `staff.manage` okur). İlk admin SQL Editor'dan verilir (`SUPABASE.md` §11).
- **049 destek:** `support_threads` (kullanıcı başına tek; `open` → `answered` → `resolved`, kategori, `client_info`, `assignee_id`, okundu zamanları, `first_response_at`), `support_messages` (`internal = true` iç not). Personel RPC'leri: `reply_support(p_thread_id, p_content, p_internal)`, `set_support_status` (053'ten beri `support.reply` ister ve `staff_actions`'a yazar), `mark_support_read`. Atama RPC'si henüz yok. Realtime açık.
- **023/053 `reports`:** `target_type` (`post`/`comment`/`user`), `target_id`, `reason`, `note`, `status` (`open`/`actioned`/`dismissed`). Kullanıcı yalnızca ekler; `reports.handle` yetkilisi okur. `resolve_report(target_type, target_id, 'actioned'|'dismissed', gerekçe)` hedefin açık raporlarını kapatır.
- **053 moderasyon:** silinmez, gizlenir. `moderate_content('post'|'comment', id, true|false, gerekçe)` → `removed_at`; gizli içerik RLS'te süzülür, `posts.remove`/`comments.remove` yetkilisi görür (mobilde de). Kim/neden `staff_actions`'ta. Gizli yorum `comment_count`'ta sayılmaya devam eder.
- **Henüz RPC'si olmayan yetkiler:** `users.ban` (Edge Function), `users.verify`, `stats.view`.
- **Gizlilik:** `users.email` ve `users.phone` istemciye okunmaz (KVKK). Panelin ihtiyacı olursa yetki kontrollü RPC ile açılır.
- **Storage:** `post-images` ve `post-videos` private; görüntülemek için signed URL.
- **Edge Functions:** `push`, `send-sms`, `panel-account` (`../dentlink/supabase/functions/`).

## Yapılacaklar (sırayla)

1. **Yetki modeli (migration 053):** _canlıda (`053_staff_permissions.sql`, 2026-11-09); smoke 31–35 geçti (2026-11-11)._
   - `staff_roles(name, permissions text[])`; panelden yeni rol tanımlanabilir. Yetki adları: `support.reply`, `reports.handle`, `posts.remove`, `comments.remove`, `users.ban`, `users.verify`, `staff.manage`, `stats.view` (gerekirse ekle).
   - `has_permission(p text)`; `has_staff_role` 049'daki policy ve RPC'lerle uyumlu kalır (önce sarmala, sonra taşı).
   - `set_staff_role` / `remove_staff` RPC'leri (`staff.manage`). Son admin kendini düşüremez.
   - `staff_actions` işlem kaydı: kim, ne, hangi hedef, gerekçe, zaman. Her personel RPC'si yazar. 2FA olmadığı için asıl güvenlik ağı bu.
   - Moderasyon silmez, gizler: `posts.removed_at` / `comments.removed_at` (+ kaldıran, gerekçe). Gizlenen içerik RLS'te süzülür, mobil uygulamada değişiklik gerekmez. Geri alınabilir.
   - `reports`'u yetkili personele okunur yap; `resolve_report` RPC'si.
2. **Panel iskeleti:** _kuruldu (2026-11-09; build geçiyor, gerçek hesapla giriş denenmedi)._ giriş (e-posta OTP), personel değilse giriş reddi, yetkiye göre menü.
   - Yapı: `src/lib/supabase.ts` (tipli client), `src/lib/errors.ts` (kod → Türkçe mesaj; yeni RPC hatası eklenince buraya), `src/auth.tsx` (`useAuth()`: `session`, `staff`, `can(p)`), `src/Layout.tsx` (`menu` dizisi: yol, etiket, yetkiler), `src/App.tsx` (rotalar; sayfalar şimdilik yer tutucu), `src/pages/Login.tsx`.
   - Giriş kullanıcı adı + şifre (`src/pages/Login.tsx`, `panelEmail`). Panel hesap açmaz. Personel satırı yoksa oturum kapanır, `/giris?reddedildi`. İlk hesap: `SUPABASE.md` §11.
   - shadcn/ui (`base-nova`, Base UI tabanlı): bileşen `npx shadcn@latest add <ad>`; `cn` paketi shadcn'in kendi paketi.
   - `.env` (publishable key, açık bilgi) repoda.
   - PWA: `public/manifest.webmanifest`, adı "Dentigo Yönetim". İkon uygulamanınkinden ayrı (kalkan içinde diş), `node scripts/icons.mjs` üretir. Service worker yok, bilerek: panel canlı veriyle çalışır, önbellek deploy sonrası eski sürümü gösterirdi.
3. **Ortak altyapı (migration yok):** _kuruldu (2026-11-11; lint + build geçiyor, tarayıcıda denenmedi)._ shadcn `dialog`, `table`. `src/components/ConfirmDialog.tsx`: geri dönüşü zor işlem önce onay ister, hata pencerede kalır. Personel sayfasında rol değiştirme (`set_staff_role`), çıkarma (`remove_staff`), Roller kartı (yetki onay kutuları, `save_staff_role`/`delete_staff_role`; yetki listesi `Staff.tsx` `permissions`, 053 CHECK'iyle aynı tutulur). `/kayit` işlem kaydı (`src/pages/AuditLog.tsx`, `staff.manage`): personel, işlem ve tarih filtresi, zamana göre "Daha fazla"; hedef kullanıcının adı gösterilir.
   - Storage: `post-images`/`post-videos` okuma policy'si her oturumlu hesaba açık (020, 046); personel signed URL alabilir, policy gerekmez.
   - Kullanan sayfayla birlikte eklenecek: gerekçe alanı (`ConfirmDialog`'a, madde 5), `signedUrl` (madde 5), `textarea`/`tabs`/`badge` (madde 4). `@tanstack/react-table` şimdilik gereksiz: sıralama/filtre sunucuda, düz shadcn `table` yetiyor.
4. **Destek kutusu `/destek` (`support.reply`, migration 055):** `assign_support_thread` (atanan personel olmalı, loglu); 049 policy'leri `has_permission('support.reply')`'a taşınır; PostgREST embed yetmezse `support_inbox` RPC. Ekran: Açık / Cevaplandı / Çözüldü / Bana atanan; açıklar en eski bekleyen önce, 24 saati geçen işaretli; cevap / iç not, durum, atama, `mark_support_read`, `client_info`, ilk cevap süresi. Realtime `support_messages` → liste tazelenir, sekme başlığında sayı, izin varsa tarayıcı bildirimi (yalnızca sayfa açıkken). Smoke 36.
5. **Moderasyon `/moderasyon` (`reports.handle`, migration 056):** `report_queue(p_status, p_limit, p_offset)` hedef başına gruplu. Önizleme (post, yorum + postu, kullanıcı; medya signed URL). Gizle (`moderate_content` + `resolve_report actioned`), geri al, reddet, banla; butonlar `posts.remove`/`comments.remove`/`users.ban`'e göre. Hedefin `staff_actions` geçmişi. Smoke 37.
6. **Kullanıcılar `/kullanicilar` (migration 057 + Edge Function `panel-user`):** `admin_search_users`, `admin_user_detail` (ban durumu, rapor sayısı; e-posta/telefon maskeli, tamamı yalnızca `users.ban` ile ve `user.view_contact` olarak loglanır), `set_user_verified` (`users.verify`, loglu). `panel-user` (`users.ban`, `panel-account` kalıbı): ban (1 gün / 7 gün / kalıcı) + global signOut + `push_tokens` silme + log; unban; personel banlanamaz. Bilinen sınır: açık access token ≤1 saat geçerli kalır. Detay sayfası: profil, postlar (gizliler dahil), raporlar, destek sohbeti, işlem geçmişi, "Personel yap". Diploma akışı kapsam dışı (ROADMAP Faz 4 kararı bekliyor). Smoke 38–39.
   - _Personel sayfası kuruldu (2026-11-11, `src/pages/Staff.tsx`, `/personel`, `staff.manage`): ekip listesi, panel hesabı açma, panel hesabının şifresini değiştirme. Rol değiştirme ve personeli çıkarma madde 3'te._
   - Panel hesabı açma ve şifre değiştirme: `panel-account` Edge Function (deploy: `--no-verify-jwt`, JWT'yi kendisi doğrular; şifre 12–72) (service_role). Önce çağıranda `has_permission('staff.manage')`, yalnızca `@panel.dentigo.invalid` hesaplarına dokunur (yoksa uygulama kullanıcısının hesabı ele geçirilebilir). Açarken: `auth.admin.createUser` (email_confirm) → `users` satırı (`username = 'panel_<ad>'`, `onboarding_completed = false`) → çağıranın JWT'siyle `set_staff_role` (yetki kontrolü + kayıt); bir adım düşerse auth kullanıcısı silinir. Şifre değişikliği `staff_actions`'a yazılır.
7. **İstatistik `/istatistik` (`stats.view`, migration 058):** `admin_stats(p_days)`: günlük kayıt, gönderi (türe göre), yorum, rapor; özet: toplam/aktif kullanıcı, açık rapor, açık destek, medyan ilk cevap süresi. KPI kutuları + CSS/SVG çubuk grafik (grafik kütüphanesi yok).
8. **İçerik yönetimi (yayından sonra, isteğe bağlı):** yeni yetki `tags.manage` (059, `staff_roles` CHECK genişler): etiket benzerlik raporu, `add_tag_alias`/`add_curated_tags`/`merge_tags` sarmalayıcıları; kullanıcı tedavileri raporu (salt okunur; `promote_other_treatment` uygulama sürümü ister, panelden çalıştırılmaz). `app_config` yapılınca sürüm düzenleme (`config.manage`). Toplu duyuru/push yok (ayrı karar).

Her madde için: migration `SUPABASE.md` kurallarıyla + smoke, `supabase gen types`, `npm run lint` + `npm run build`, mobil ↔ panel uçtan uca deneme, `support` rolündeki hesapla yetkisiz eylemin `42501` aldığı kontrol.

## Çalışma kuralları

- Her yeni RPC/policy için `SUPABASE.md`'deki smoke test kalıbıyla en az bir test ekle.
- Kullanıcıya ham hata gösterme; Postgres hata kodlarını Türkçe mesaja çevir.
- `select('*')` yok; gereken kolonları listele.
- Kendiliğinden commit atma.
