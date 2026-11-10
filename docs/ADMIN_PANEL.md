# Dentigo Admin Paneli — Devir Notu (panel projesindeki ajan için)

> Bu dosya `dentlink` (mobil uygulama) reposunda durur ve iki proje için ortak kaynaktır. Panel projesinin `CLAUDE.md`'si bunu import eder. Panelle ilgili bir karar değişirse burayı güncelle.

## Ürün

Dentigo, diş hekimleri ve öğrenciler için mobil sosyal platform (Flutter + Supabase): vaka ve forum paylaşımı, 2. el ilan (Ticaret), takip, DM, bildirim, destek sohbeti. Ayrıntı: `../dentlink/agents.md`. Mobil uygulama `com.atlas.dentlink`; Supabase projesi `dentlink_backend`.

Panelin amacı: tüm sistemi tarayıcıdan yönetmek ve moderatör kullanıcılara belli yetkiler vermek.

## Kararlar (2026-11-09)

- **Web SPA:** React + Vite + TypeScript. `npm run build` → `dist/`, sahibinin kendi hostingine statik olarak yüklenir. Node sunucusu yok, Next.js yok. Sunucuda SPA yönlendirmesi: bilinmeyen yol → `index.html`.
- **Kütüphaneler:** `@supabase/supabase-js`, TanStack Query, react-router, Tailwind + shadcn/ui, TanStack Table. Gereksiz bağımlılık ekleme.
- **Dil:** arayüz yalnızca Türkçe (dahili araç, l10n yok).
- **2FA yok.** Personel, mobil uygulamadaki gibi e-posta OTP ile kendi hesabıyla girer (`signInWithOtp`).
- **Panel yalnızca arayüzdür, yetki veritabanındadır.** Panel mobil uygulamayla aynı publishable (anon) key'i kullanır. `service_role` key panele asla girmez. Her yetki kontrolü RLS ve `SECURITY DEFINER` RPC'lerde yapılır; panelde bir hata olsa bile kullanıcı yetkisinin dışına çıkamaz. Arayüzdeki menü gizleme yalnızca kolaylıktır.
- `service_role` gerektiren işler (ör. `auth.users` ban) Edge Function'da yapılır; fonksiyon önce çağıranın yetkisini kontrol eder.

## Supabase

- URL: `https://lknvufbxekceevdblgmq.supabase.co` · ref `lknvufbxekceevdblgmq`
- Publishable key: `../dentlink/lib/main.dart` içindeki `publishableKey` (açık bilgi, `.env` içinde `VITE_` değişkeni olarak tut).
- Tipler: `supabase gen types typescript --project-id lknvufbxekceevdblgmq > src/types/database.ts`. Her migration'dan sonra yeniden üret, elle model yazma.
- **Şemanın asıl kaynağı:** `../dentlink/supabase/migrations/*.sql`. Kurallar: `../dentlink/docs/SUPABASE.md` (özellikle §1 migration akışı, §2 RLS/GRANT, §3 storage, §6 moderasyon, §11 destek ve personel). Önce bunları oku.

### Migration kuralı (önemli)

- Panel reposunda migration **yazılmaz**. Şema değişikliği `../dentlink/supabase/migrations/` altında, sıradaki numarayla (son: `053_…`) ve `SUPABASE.md` kurallarıyla yazılır.
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
- **Edge Functions:** `push`, `send-sms` (`../dentlink/supabase/functions/`).

## Yapılacaklar (sırayla)

1. **Yetki modeli (migration 053):** _canlıda (`053_staff_permissions.sql`, 2026-11-09); smoke 31–34 bekliyor._
   - `staff_roles(name, permissions text[])`; panelden yeni rol tanımlanabilir. Yetki adları: `support.reply`, `reports.handle`, `posts.remove`, `comments.remove`, `users.ban`, `users.verify`, `staff.manage`, `stats.view` (gerekirse ekle).
   - `has_permission(p text)`; `has_staff_role` 049'daki policy ve RPC'lerle uyumlu kalır (önce sarmala, sonra taşı).
   - `set_staff_role` / `remove_staff` RPC'leri (`staff.manage`). Son admin kendini düşüremez.
   - `staff_actions` işlem kaydı: kim, ne, hangi hedef, gerekçe, zaman. Her personel RPC'si yazar. 2FA olmadığı için asıl güvenlik ağı bu.
   - Moderasyon silmez, gizler: `posts.removed_at` / `comments.removed_at` (+ kaldıran, gerekçe). Gizlenen içerik RLS'te süzülür, mobil uygulamada değişiklik gerekmez. Geri alınabilir.
   - `reports`'u yetkili personele okunur yap; `resolve_report` RPC'si.
2. **Panel iskeleti:** _kuruldu (2026-11-09; build geçiyor, gerçek hesapla giriş denenmedi)._ giriş (e-posta OTP), personel değilse giriş reddi, yetkiye göre menü.
   - Yapı: `src/lib/supabase.ts` (tipli client), `src/lib/errors.ts` (kod → Türkçe mesaj; yeni RPC hatası eklenince buraya), `src/auth.tsx` (`useAuth()`: `session`, `staff`, `can(p)`), `src/Layout.tsx` (`menu` dizisi: yol, etiket, yetkiler), `src/App.tsx` (rotalar; sayfalar şimdilik yer tutucu), `src/pages/Login.tsx`.
   - Giriş `shouldCreateUser: false`: panel hesap açmaz. Personel satırı yoksa oturum kapanır, `/giris?reddedildi`.
   - shadcn/ui (`base-nova`, Base UI tabanlı): bileşen `npx shadcn@latest add <ad>`; `cn` paketi shadcn'in kendi paketi.
   - `.env` (publishable key, açık bilgi) ve `public/.htaccess` (Apache SPA yönlendirmesi) repoda.
3. **Destek kutusu:** açıklar üstte, en eski bekleyen önce; cevap, iç not, durum, atama, ilk cevap süresi; realtime ile yeni mesaj bildirimi.
4. **Moderasyon kuyruğu:** hedef başına gruplanmış raporlar, içerik önizleme, gizle / geri al / reddet, kullanıcıyı banla (Edge Function).
5. **Kullanıcılar:** arama, profil, `is_verified` onayı (diploma akışı henüz kararsız, ROADMAP Faz 4), personel ve rol yönetimi.
6. **İstatistik:** günlük kayıt, gönderi, açık rapor, destek bekleme süresi.

## Çalışma kuralları

- Her yeni RPC/policy için `SUPABASE.md`'deki smoke test kalıbıyla en az bir test ekle.
- Kullanıcıya ham hata gösterme; Postgres hata kodlarını Türkçe mesaja çevir.
- `select('*')` yok; gereken kolonları listele.
- Kendiliğinden commit atma.
