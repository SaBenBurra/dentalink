-- Faz 2 yük testi (Bitti tanımı): 1.000 post + 200 mesaj.
-- Migration değil; SQL Editor'dan ya da `supabase db query --linked -f` ile
-- elle çalıştırılır. Tüm satırlar "[seed]" ile başlar, geri almak için
-- load_test_cleanup.sql. Mevcut tek sohbetin iki kullanıcısını kullanır.
begin;

create temp table seed_pair on commit drop as
  select id, user1_id, user2_id, last_message_at, last_message_preview
    from public.conversations
   order by created_at
   limit 1;

do $$
begin
  if not exists (select 1 from seed_pair) then
    raise exception 'seed için en az bir sohbet (iki kullanıcı) gerekli';
  end if;
end $$;

-- Postlar: iki kullanıcıya dönüşümlü, vaka/soru karışık, son ~83 güne yayılmış.
insert into public.posts (user_id, type, title, content, branch, created_at)
select
  case when i % 2 = 0 then sp.user1_id else sp.user2_id end,
  case when i % 3 = 0 then 'question'::public.post_type else 'case'::public.post_type end,
  format('[seed] %s #%s', case when i % 3 = 0 then 'Soru' else 'Vaka' end, i),
  format('[seed] Yük testi içeriği %s. Kanal tedavisi, implant, ortodonti ve periodontal cerrahi üzerine örnek metin.', i),
  case when i % 3 = 0 then null
       else (enum_range(null::public.dental_branch))[1 + i % array_length(enum_range(null::public.dental_branch), 1)]
  end,
  now() - make_interval(hours => 2 * i)
from generate_series(1, 1000) i, seed_pair sp;

-- Mesajlar: mevcut mesajlardan eski (sohbette yukarı kaydırınca gelir), okunmuş.
insert into public.messages (conversation_id, sender_id, receiver_id, content, is_read, created_at)
select
  sp.id,
  case when i % 2 = 0 then sp.user1_id else sp.user2_id end,
  case when i % 2 = 0 then sp.user2_id else sp.user1_id end,
  format('[seed] mesaj %s', i),
  true,
  coalesce((select min(created_at) from public.messages m where m.conversation_id = sp.id), now())
    - make_interval(mins => 201 - i)
from generate_series(1, 200) i, seed_pair sp;

-- Trigger son mesajı eski seed mesajına çekti; geri koy. Okunmamış sayılar reconcile ile.
update public.conversations c
   set last_message_at = sp.last_message_at, last_message_preview = sp.last_message_preview
  from seed_pair sp where c.id = sp.id;

select public.reconcile_counters();
commit;
