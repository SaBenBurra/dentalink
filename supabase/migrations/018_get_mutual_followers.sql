-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 018: ortak takipçiler RPC'si (DATA-12 sonrası)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Profili (p_user_id) takip edenlerden oturumdaki kullanıcının takip ettikleri.
-- Kesişim DB'de alınır; istemci tüm takipçi listesini çekmez. Dönen JSON:
--   { "total": <ortak takipçi sayısı>,
--     "users": [ en son takip edenden başlayarak en fazla p_limit kullanıcı ] }
-- Kendi profilinde ve oturumsuzken total 0 döner. SECURITY INVOKER: follows ve
-- users üzerindeki mevcut RLS/GRANT kuralları aynen geçerlidir.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.get_mutual_followers(
  p_user_id uuid,
  p_limit   int DEFAULT 3
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  WITH mutual AS (
    SELECT u.id, u.full_name, u.username, u.avatar_url, u.title,
           u.is_verified, u.created_at, f.created_at AS followed_at
      FROM public.follows f
      JOIN public.follows mine
        ON mine.following_id = f.follower_id
       AND mine.follower_id = auth.uid()
      JOIN public.users u ON u.id = f.follower_id
     WHERE f.following_id = p_user_id
       AND p_user_id <> auth.uid()
  ),
  shown AS (
    SELECT * FROM mutual
     ORDER BY followed_at DESC, id DESC
     LIMIT least(greatest(p_limit, 0), 20)
  )
  SELECT jsonb_build_object(
    'total', (SELECT count(*) FROM mutual),
    'users', coalesce(
      (SELECT jsonb_agg(to_jsonb(s) - 'followed_at' ORDER BY s.followed_at DESC, s.id DESC)
         FROM shown s),
      '[]'::jsonb
    )
  );
$$;

REVOKE EXECUTE ON FUNCTION public.get_mutual_followers(uuid, int) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_mutual_followers(uuid, int) TO authenticated;
