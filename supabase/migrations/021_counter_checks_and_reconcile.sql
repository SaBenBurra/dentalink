-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 021: sayaç CHECK'leri ve uzlaştırma (DATA-18)
-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. reconcile_counters(): her sayacı kaynak tablosundaki gerçek sayıya eşitler,
--    yalnızca farklı olan satırları günceller ve düzeltilen satır sayılarını
--    jsonb döner. İstemciye kapalı; SQL Editor'dan ya da ileride pg_cron ile:
--      select public.reconcile_counters();
-- 2. Migration içinde bir kez çalıştırılır, ardından tüm sayaçlara `>= 0`
--    CHECK'i eklenir. 001'deki satır içi CHECK'ler, tablo önceden var olduğu
--    için canlıda oluşmamış olabilir (001:103-105).
-- Trigger'lardaki GREATEST(…,0) kalır: sapma olsa bile unlike/unfollow hata
-- vermesin; sapmayı CHECK değil uzlaştırma düzeltir.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.reconcile_counters()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb := '{}'::jsonb;
  v_n      bigint;
BEGIN
  -- shortcut: tablo kilitlemeden sayar; sayım ile güncelleme arasına giren
  -- bir beğeni bir sonraki çalıştırmaya kadar ±1 kalabilir. Sorun olursa
  -- satır kilidi (FOR UPDATE) ekle.

  UPDATE public.posts p SET like_count = s.n
    FROM (SELECT p2.id, count(l.id) AS n
            FROM public.posts p2
            LEFT JOIN public.likes l ON l.post_id = p2.id
           GROUP BY p2.id) s
   WHERE s.id = p.id AND p.like_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.like_count', v_n);

  UPDATE public.posts p SET comment_count = s.n
    FROM (SELECT p2.id, count(c.id) AS n
            FROM public.posts p2
            LEFT JOIN public.comments c ON c.post_id = p2.id
           GROUP BY p2.id) s
   WHERE s.id = p.id AND p.comment_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.comment_count', v_n);

  UPDATE public.posts p SET bookmark_count = s.n
    FROM (SELECT p2.id, count(b.id) AS n
            FROM public.posts p2
            LEFT JOIN public.bookmarks b ON b.post_id = p2.id
           GROUP BY p2.id) s
   WHERE s.id = p.id AND p.bookmark_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.bookmark_count', v_n);

  -- view_count'un kaynak tablosu yok; yalnızca negatif değer sıfırlanır.
  UPDATE public.posts SET view_count = 0 WHERE view_count < 0;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.view_count', v_n);

  UPDATE public.comments c SET like_count = s.n
    FROM (SELECT c2.id, count(l.id) AS n
            FROM public.comments c2
            LEFT JOIN public.likes l ON l.comment_id = c2.id
           GROUP BY c2.id) s
   WHERE s.id = c.id AND c.like_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('comments.like_count', v_n);

  UPDATE public.users u SET followers_count = s.n
    FROM (SELECT u2.id, count(f.follower_id) AS n
            FROM public.users u2
            LEFT JOIN public.follows f ON f.following_id = u2.id
           GROUP BY u2.id) s
   WHERE s.id = u.id AND u.followers_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('users.followers_count', v_n);

  UPDATE public.users u SET following_count = s.n
    FROM (SELECT u2.id, count(f.following_id) AS n
            FROM public.users u2
            LEFT JOIN public.follows f ON f.follower_id = u2.id
           GROUP BY u2.id) s
   WHERE s.id = u.id AND u.following_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('users.following_count', v_n);

  UPDATE public.users u SET posts_count = s.n
    FROM (SELECT u2.id, count(p.id) AS n
            FROM public.users u2
            LEFT JOIN public.posts p ON p.user_id = u2.id
           GROUP BY u2.id) s
   WHERE s.id = u.id AND u.posts_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('users.posts_count', v_n);

  UPDATE public.tags t SET usage_count = s.n
    FROM (SELECT t2.id, count(pt.post_id) AS n
            FROM public.tags t2
            LEFT JOIN public.post_tags pt ON pt.tag_id = t2.id
           GROUP BY t2.id) s
   WHERE s.id = t.id AND t.usage_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('tags.usage_count', v_n);

  -- Okunmamış = alıcının is_read = false mesajları (trigger ve
  -- mark_messages_as_read ile aynı anlam; soft delete ayrıca sayılmaz).
  UPDATE public.conversations c
     SET user1_unread_count = s.n1, user2_unread_count = s.n2
    FROM (SELECT c2.id,
                 count(m.id) FILTER (WHERE m.receiver_id = c2.user1_id) AS n1,
                 count(m.id) FILTER (WHERE m.receiver_id = c2.user2_id) AS n2
            FROM public.conversations c2
            LEFT JOIN public.messages m
              ON m.conversation_id = c2.id AND m.is_read = false
           GROUP BY c2.id) s
   WHERE s.id = c.id
     AND (c.user1_unread_count IS DISTINCT FROM s.n1
       OR c.user2_unread_count IS DISTINCT FROM s.n2);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('conversations.unread_count', v_n);

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.reconcile_counters() FROM public, anon, authenticated;

-- Mevcut sapmayı CHECK'lerden önce düzelt.
SELECT public.reconcile_counters();

-- ─────────────────────────────────────────────────────────────────────────────
-- `>= 0` CHECK'leri (mevcut satır ihlal ederse migration bütünüyle geri alınır)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_like_count_nonneg;
ALTER TABLE public.posts ADD CONSTRAINT posts_like_count_nonneg CHECK (like_count >= 0);
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_comment_count_nonneg;
ALTER TABLE public.posts ADD CONSTRAINT posts_comment_count_nonneg CHECK (comment_count >= 0);
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_bookmark_count_nonneg;
ALTER TABLE public.posts ADD CONSTRAINT posts_bookmark_count_nonneg CHECK (bookmark_count >= 0);
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_view_count_nonneg;
ALTER TABLE public.posts ADD CONSTRAINT posts_view_count_nonneg CHECK (view_count >= 0);

ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_like_count_nonneg;
ALTER TABLE public.comments ADD CONSTRAINT comments_like_count_nonneg CHECK (like_count >= 0);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_followers_count_nonneg;
ALTER TABLE public.users ADD CONSTRAINT users_followers_count_nonneg CHECK (followers_count >= 0);
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_following_count_nonneg;
ALTER TABLE public.users ADD CONSTRAINT users_following_count_nonneg CHECK (following_count >= 0);
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_posts_count_nonneg;
ALTER TABLE public.users ADD CONSTRAINT users_posts_count_nonneg CHECK (posts_count >= 0);

ALTER TABLE public.tags DROP CONSTRAINT IF EXISTS tags_usage_count_nonneg;
ALTER TABLE public.tags ADD CONSTRAINT tags_usage_count_nonneg CHECK (usage_count >= 0);

ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_user1_unread_nonneg;
ALTER TABLE public.conversations ADD CONSTRAINT conversations_user1_unread_nonneg CHECK (user1_unread_count >= 0);
ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_user2_unread_nonneg;
ALTER TABLE public.conversations ADD CONSTRAINT conversations_user2_unread_nonneg CHECK (user2_unread_count >= 0);
