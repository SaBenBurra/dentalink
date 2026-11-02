-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 039: Kullanıcı araması yalnızca ad üzerinden
-- ═══════════════════════════════════════════════════════════════════════════════
-- Otomatik üretilen kullanıcı adı ("ahmet_celik_323259") arayüzde görünmüyor
-- ama aramaya giriyordu: "32" yazınca alakasız kullanıcı çıkıyordu. Üniversite
-- de kaldırıldı; arama yalnızca ad soyad üzerinden yapılır.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.users ALTER COLUMN search_vector SET EXPRESSION AS (
  to_tsvector('simple', public.search_fold(full_name))
);

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
     AND u.id IS DISTINCT FROM (select auth.uid())
     AND NOT public.is_blocked_between((select auth.uid()), u.id)
   ORDER BY ts_rank(u.search_vector, q.tsq) DESC,
            u.followers_count DESC,
            u.id
   LIMIT least(greatest(p_limit, 1), 50);
$$;
