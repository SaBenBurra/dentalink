# Supabase — Çalışma Kuralları

> **Proje:** `dentlink_backend` · ref `lknvufbxekceevdblgmq` · eu-central-1 · Postgres 17
> **Asıl kaynak:** `supabase/migrations/*.sql`. Şemayı dokümana kopyalama; migration'ları oku.

---

## 1. Altın kural: şema değişikliği yalnızca migration ile yapılır

Dashboard SQL Editor'da **kalıcı değişiklik yapma**. Daha önce böyle yapıldı ve uzak DB'nin migration geçmişi boş kaldı (AUDIT `DATA-1`).

```bash
supabase link --project-ref lknvufbxekceevdblgmq   # bir kere
supabase migration new kisa_aciklama               # yeni dosya oluşturur
# dosyayı yaz
supabase db push --dry-run                         # neyin uygulanacağını gör
supabase db push                                   # uygula
supabase migration list                            # local == remote olmalı
```

- **Dosya adı:** Dosyalar `001_…` biçiminde sıralı; yeni dosya bir sonraki numarayı alır (son: `023_…`).
- **Idempotent yaz:**
  - `CREATE OR REPLACE FUNCTION`
  - `DROP POLICY IF EXISTS …;` ardından `CREATE POLICY …`
  - `CREATE INDEX IF NOT EXISTS`
  - `ADD COLUMN IF NOT EXISTS`
  - `EXCEPTION WHEN OTHERS THEN NULL` **kullanma**; hataları gizliyor.
  - plpgsql gövdesinde `CASE … END` ifadesi **kullanma**: CLI'ın SQL bölücüsü onu blok sonu sanıp dosyayı yanlış yerden kesiyor. `IF` ya da değişken kullan.
- **Yayınlanmış migration'ı düzenleme.** Düzeltme her zaman yeni bir migration'dır.
- `supabase start`/`db reset` bu ortamda yok (docker yok). Yalnızca uzak proje kullanılır.

---

## 2. Güvenlik modeli (RLS + GRANT)

RLS **hangi satırlara** dokunulabileceğini belirler; GRANT **hangi kolonlara**. İkisi birlikte gerekir.

| Kural | Neden |
|---|---|
| `authenticated` rolüne UPDATE/INSERT'i **kolon bazlı** ver: `GRANT UPDATE (title, content) ON posts TO authenticated`. | Aksi halde kullanıcı kendi satırındaki `is_verified`, `like_count` gibi alanları yazabilir. |
| Sayaçlar (`*_count`), `is_verified`, `is_best_answer`, `is_solved`, `unread_count` **yalnızca trigger veya RPC** ile değişir. | Kullanıcının sahte rakam üretmesini engeller. |
| Birden fazla satıra dokunan veya bir kural uygulayan işlemler `SECURITY DEFINER` RPC ile yapılır, ilgili tabloya doğrudan yazma revoke edilir. | Örnek: `send_message`, `mark_best_answer`, `mark_messages_as_read`. |
| Her `SECURITY DEFINER` fonksiyonda `SET search_path = ''` (ya da en azından `public`), fonksiyonun içinde `auth.uid()` kontrolü ve `REVOKE EXECUTE … FROM public, anon` bulunur. | Yetki yükseltmeyi engeller. |
| `notifications` tablosuna istemci **asla** yazmaz; yalnızca trigger'lar yazar. | Sahte bildirimi engeller. |
| `users.email` ve `users.phone` istemciye **okunmaz**. | KVKK. |
| Sorgularda `select('*')` / `users(*)` kullanma; gereken kolonları listele. | Yeni kolonlar istemeden sızmasın. |

---

## 3. Storage

| Bucket | Erişim | Path kuralı | Not |
|---|---|---|---|
| `avatars` | public read | `{auth.uid()}/…` | 012'de tanımlandı; 2MB limit (019) |
| `post-images` | **private**, okuma yalnızca `authenticated` (020) | `{auth.uid()}/…` | 2MB limit (019), istemci WebP yükler; görseller 1 günlük signed URL ile gösterilir (SEC-9) |

- Yazma ve silme policy'si: `(storage.foldername(name))[1] = auth.uid()::text`.
- **Sıra:** önce yeni dosyayı yükle, DB'yi güncelle, **en son** eski dosyayı sil. Tersi veri kaybına yol açar (AUDIT `DATA-7`, `DATA-8`).

---

## 4. Realtime

- Yayına eklenen tablolar: `messages`, `conversations` (012), `notifications` (013).
- İstemcide kanal kapatılırken `client.removeChannel(channel)` çağrılır; yalnızca `unsubscribe()` yetmez.
- Her olayda tüm listeyi yeniden çekme; gelen `payload.newRecord`'u state'e ekle.

---

## 5. RLS smoke testleri

Her güvenlik migration'ından sonra SQL Editor'da çalıştır. Her blok `rollback` ile bitiyor, yani veri değişmez. `<A>`, `<B>`, `<C>` yerine `public.users`'tan üç gerçek kullanıcı id'si koy; `<CONV_AB>` A ile B arasındaki bir konuşmanın id'si.

```sql
-- 1) Kullanıcı kendini doğrulanmış yapamamalı → BEKLENEN: permission denied
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
update public.users set is_verified = true where id = '<A>';
rollback;

-- 2) Kendi bio'sunu güncelleyebilmeli → BEKLENEN: UPDATE 1
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
update public.users set bio = 'test' where id = '<A>';
rollback;

-- 3) public.users'ta e-posta/telefon tutulmaz (012'de kaldırıldı) → BEKLENEN: column "email" does not exist
select email from public.users limit 1;

-- 4) messages'a doğrudan insert yasak, mesaj yalnızca send_message ile (014) → BEKLENEN: permission denied
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<C>","role":"authenticated"}', true);
insert into public.messages (conversation_id, sender_id, receiver_id, content)
values ('<CONV_AB>', '<C>', '<A>', 'hack');
rollback;

-- 5) Bildirim insert'ü yasak → BEKLENEN: permission denied
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
insert into public.notifications (user_id, actor_id, type) values ('<B>', '<A>', 'follow');
rollback;

-- 6) Aynı kullanıcı iki farklı postu beğenebilmeli → BEKLENEN: INSERT 0 2
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
insert into public.likes (user_id, post_id)
select '<A>', id from public.posts
where id not in (select post_id from public.likes where user_id = '<A>' and post_id is not null)
limit 2;
rollback;

-- 7) Post sayaçları elle değiştirilemez → BEKLENEN: permission denied
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
update public.posts set like_count = 9999 where user_id = '<A>';
rollback;

-- 8) Takip, alıcıya trigger ile bildirim yazar (013) → BEKLENEN: 1
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
delete from public.follows where follower_id = '<A>' and following_id = '<C>';
insert into public.follows (follower_id, following_id) values ('<A>', '<C>');
reset role;
select count(*) from public.notifications
where user_id = '<C>' and actor_id = '<A>' and type = 'follow' and created_at = now();
rollback;

-- 9) send_message: gönderen auth.uid(), sohbet yoksa oluşur (014) → BEKLENEN: 1 satır, content = 'smoke'
--    Kendine gönderim → invalid receiver; boş içerik → invalid content; anon → permission denied
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
select sender_id, content from public.send_message('<B>', '  smoke  ');
rollback;

-- 10) create_post: post + görsel + etiket tek işlemde (015) → BEKLENEN: n_tags = 1, branch = null
--     Doğrudan posts/tags insert → permission denied; olmayan görsel yolu → invalid image path
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
select set_config('t.id', public.create_post('question', 'Başlık', 'içerik', null, null,
  '[{"name":"İmplant","slug":"implant"},{"name":"implant","slug":"implant"}]')::text, true);
select (select count(*) from public.post_tags where post_id = current_setting('t.id')::uuid) n_tags, branch
from public.posts where id = current_setting('t.id')::uuid;
rollback;

-- 11) update_post: sahibi düzenler, etiketler eşitlenir (016) → BEKLENEN: title = 'Yeni', n_tags = 1
--     Başka kullanıcı (<B>) → post not found; doğrudan UPDATE posts → permission denied
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
select set_config('t.id', public.create_post('question', 'Eski', 'içerik', null, null,
  '[{"name":"a","slug":"a"},{"name":"b","slug":"b"}]')::text, true);
select public.update_post(current_setting('t.id')::uuid, 'Yeni', 'içerik', null, '[{"name":"b","slug":"b"}]');
select title, (select count(*) from public.post_tags where post_id = p.id) n_tags
from public.posts p where id = current_setting('t.id')::uuid;
rollback;

-- 12) mark/unmark_best_answer (017) → BEKLENEN: after_mark = true, after_unmark = false
--     SQL Editor yalnızca son sorgunun sonucunu gösterir; ikisi tek satırda döner.
--     Vaka postunda mark → best answer only for questions; en iyi cevabı silmek de is_solved'u false yapar
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
select set_config('t.id', public.create_post('question', 'Soru', 'içerik')::text, true);
with c as (
  insert into public.comments (post_id, user_id, content)
  values (current_setting('t.id')::uuid, '<A>', 'cevap') returning id
) select set_config('t.c', id::text, true) from c;
select public.mark_best_answer(current_setting('t.c')::uuid);
select set_config('t.after_mark',
  (select is_solved::text from public.posts where id = current_setting('t.id')::uuid), true);
select public.unmark_best_answer(current_setting('t.c')::uuid);
select current_setting('t.after_mark') after_mark, is_solved after_unmark
from public.posts where id = current_setting('t.id')::uuid;
rollback;

-- 13) Uzunluk ve etiket sınırları (017) → BEKLENEN: too many tags (23514)
--     2001 karakterlik yorum → comments_content_length; 31 karakterlik etiket → tags_name_length
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
select public.create_post('question', 'Soru', 'içerik', null, null,
  '[{"name":"a","slug":"a"},{"name":"b","slug":"b"},{"name":"c","slug":"c"},
    {"name":"d","slug":"d"},{"name":"e","slug":"e"},{"name":"f","slug":"f"}]');
rollback;

-- 14) Sayaçlar (021) → BEKLENEN: ilk blok permission denied;
--     ikinci blok (SQL Editor, postgres) posts_like_count_nonneg (23514)
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
select public.reconcile_counters();
rollback;
begin;
update public.posts set like_count = -1 where id = (select id from public.posts limit 1);
rollback;

-- 15) Rapor (023) → BEKLENEN: ilk insert INSERT 0 1; başkası adına insert
--     row-level security hatası; select permission denied
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
insert into public.reports (reporter_id, target_type, target_id, reason)
values ('<A>', 'user', '<B>', 'spam');
insert into public.reports (reporter_id, target_type, target_id, reason)
values ('<B>', 'user', '<C>', 'spam');
rollback;
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
select * from public.reports;
rollback;

-- 16) Engel iki yönlü gizler (023) → BEKLENEN: B, A'nın postlarını görmez (0), iki yönde takip yok (0)
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
insert into public.blocks (blocker_id, blocked_id) values ('<A>', '<B>');
select set_config('request.jwt.claims', '{"sub":"<B>","role":"authenticated"}', true);
select count(*) as a_posts_seen_by_b from public.posts where user_id = '<A>';
select count(*) as follows_ab from public.follows
 where (follower_id, following_id) in (('<A>','<B>'), ('<B>','<A>'));
rollback;

-- 17) Engelliyken mesaj (023) → BEKLENEN: blocked (42501)
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<A>","role":"authenticated"}', true);
insert into public.blocks (blocker_id, blocked_id) values ('<A>', '<B>');
select set_config('request.jwt.claims', '{"sub":"<B>","role":"authenticated"}', true);
select public.send_message('<A>', 'merhaba');
rollback;

-- 18) Hesap silme (024) → BEKLENEN: anon için permission denied. Gerçek silme
--     yalnızca uygulamadan bir test hesabıyla denenir (geri alınamaz).
begin;
set local role anon;
select public.delete_account();
rollback;

-- 19) Etiket önerisi (025) → BEKLENEN: 'imp' ve 'cene' (ASCII) sonuç döner, 'implant'
--     ilk sırada; 1 karakter boş; anon için permission denied
begin;
set local role authenticated;
select public.suggest_tags('imp');
select public.suggest_tags('cene');
select count(*) as one_char from public.suggest_tags('i');
rollback;
begin;
set local role anon;
select public.suggest_tags('imp');
rollback;
```

---

## 6. Moderasyon kuyruğu (023)

Raporlar istemciye okunmaz; kuyruk Dashboard → SQL Editor'dan yönetilir.

```sql
-- açık raporlar, hedef başına sayı
select target_type, target_id, count(*) as reports, array_agg(distinct reason) as reasons,
       min(created_at) as first_at
from public.reports where status = 'open'
group by target_type, target_id order by reports desc, first_at;

-- içeriği kaldır (post/yorum) ve raporu kapat
delete from public.posts where id = '<POST>';
update public.reports set status = 'actioned' where target_id = '<POST>';

-- asılsız rapor
update public.reports set status = 'dismissed' where target_id = '<ID>';
```

Kullanıcıyı kapatmak için Dashboard → Authentication → kullanıcı → Ban user. Hesap silme (024, `delete_account`) `auth.users` satırını siler; public verisi cascade ile gider. Bilinen sınır: karşı kullanıcının sohbet geçmişi de silinir. Storage dosyalarını istemci RPC'den önce siler.

---

## 7. Canlı durumu salt-okunur inceleme

```sql
-- tablo yetkileri
select grantee, table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public' and grantee in ('anon','authenticated')
order by table_name, grantee, privilege_type;

-- kolon yetkileri
select grantee, table_name, column_name, privilege_type
from information_schema.column_privileges
where table_schema = 'public' and grantee = 'authenticated'
order by table_name, privilege_type, column_name;

-- policy'ler
select tablename, policyname, cmd, qual, with_check
from pg_policies where schemaname in ('public','storage') order by tablename;

-- realtime yayını
select * from pg_publication_tables where pubname = 'supabase_realtime';

-- bucket'lar
select id, public from storage.buckets;
```
