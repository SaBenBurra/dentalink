-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 067: Doğrulanmamış hesap aramada görünmez, duyuru almaz
-- ═══════════════════════════════════════════════════════════════════════════════
-- Arama: search_user_ids, suggested_user_ids ve popular_user_scores yalnızca
--   doğrulanmış hesapları döner (066 sonrası kayıt olan ya da doğrulaması kaldırılan
--   hesap başkalarına önerilmez). İmzalar ve sıralama aynı.
-- Duyuru: FCM topic'i cihazda yönetildiği için sunucu doğrulanmamış hesabı
--   dışlayamıyordu. push fonksiyonu artık broadcast_push_tokens'ın verdiği
--   cihazlara gönderir: üye (066) ve duyuruyu kapatmamış. Kapatma tercihi
--   push_tokens.announcements'ta (set_push_announcements, cihaz başına);
--   uygulama topic aboneliğinden çıkar. Eski sürüm topic'ten çıkmaz ama topic'e
--   artık gönderilmez; tercih değiştiremez (varsayılan açık).
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Arama ve öneriler ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.search_user_ids(p_query text, p_limit integer DEFAULT 30)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT u.id
    FROM public.users u,
         (SELECT public.search_tsquery(p_query, false) AS tsq) q
   WHERE q.tsq IS NOT NULL
     AND u.search_vector @@ q.tsq
     AND u.onboarding_completed
     AND u.is_verified
     AND u.id IS DISTINCT FROM (select auth.uid())
     AND NOT public.is_blocked_between((select auth.uid()), u.id)
   ORDER BY ts_rank(u.search_vector, q.tsq) DESC,
            u.followers_count DESC,
            u.id
   LIMIT least(greatest(p_limit, 1), 50);
$$;

CREATE OR REPLACE FUNCTION public.suggested_user_ids(p_limit integer DEFAULT 20)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT u.id
    FROM public.users u
    LEFT JOIN public.users me ON me.id = (select auth.uid())
   WHERE u.id IS DISTINCT FROM (select auth.uid())
     AND u.onboarding_completed
     AND u.is_verified
     AND NOT public.is_blocked_between((select auth.uid()), u.id)
   ORDER BY EXISTS (
              SELECT 1 FROM public.follows f
               WHERE f.follower_id = (select auth.uid()) AND f.following_id = u.id
            ) DESC,
            EXISTS (
              SELECT 1 FROM public.follows f
               WHERE f.follower_id = u.id AND f.following_id = (select auth.uid())
            ) DESC,
            (u.university = nullif(me.university, '')) IS TRUE DESC,
            (u.city = nullif(me.city, '')) IS TRUE DESC,
            u.followers_count DESC,
            u.id
   LIMIT least(greatest(p_limit, 1), 50);
$$;

CREATE OR REPLACE FUNCTION public.popular_user_scores(
  p_now timestamptz DEFAULT now()
)
RETURNS TABLE (user_id uuid, score float8)
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  WITH scores AS (
    SELECT p.user_id,
           public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                 p.view_count, p_now - p.created_at) AS score,
           p.like_count + p.comment_count + p.bookmark_count AS engagement
      FROM public.posts p
     WHERE p.created_at > p_now - interval '30 days'
    UNION ALL
    SELECT c.user_id,
           0.25 * (c.like_count + 2 * c.reply_count)::float8
             / power(greatest(extract(epoch FROM p_now - c.created_at)::float8 / 3600, 0) + 2, 1.5),
           c.like_count + c.reply_count
      FROM public.comments c
     WHERE c.created_at > p_now - interval '30 days'
       AND c.like_count + c.reply_count > 0
  )
  SELECT u.id, sum(s.score)
    FROM public.users u
    JOIN scores s ON s.user_id = u.id
   WHERE u.onboarding_completed AND u.is_verified
   GROUP BY u.id
  HAVING sum(s.engagement) > 0;
$$;

-- ─── Duyuru cihazları ───────────────────────────────────────────────────────
ALTER TABLE public.push_tokens
  ADD COLUMN IF NOT EXISTS announcements boolean NOT NULL DEFAULT true;

CREATE OR REPLACE FUNCTION public.set_push_announcements(p_token text, p_enabled boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF p_enabled IS NULL THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  UPDATE public.push_tokens SET announcements = p_enabled
   WHERE token = p_token AND user_id = auth.uid();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_push_announcements(text, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_push_announcements(text, boolean) TO authenticated;

-- Yalnızca push fonksiyonu (service_role) çağırır.
CREATE OR REPLACE FUNCTION public.broadcast_push_tokens()
RETURNS TABLE (token text, platform text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT t.token, t.platform
    FROM public.push_tokens t
   WHERE t.announcements AND public.is_app_member(t.user_id);
$$;

REVOKE EXECUTE ON FUNCTION public.broadcast_push_tokens() FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.broadcast_push_tokens() TO service_role;
