-- 069: Keşfet tür sekmeleri (Tümü / Kişiler / Vakalar / Forum / Ticaret).
--
-- popular_post_ids'e p_type eklenir: verilirse yalnızca o türden postlar.
-- Ticaret sekmesi (p_type = 'listing') satılmamış ilanları metin aranmadan da
-- listeler; Tümü (p_type NULL) eskisi gibi ilanı yalnızca metin aramasında gösterir.
-- Gövdenin geri kalanı 052 ile aynı.
--
-- Geri alma: bu imza düşürülür, 040'taki imza 052'deki gövdeyle yeniden kurulur.

DROP FUNCTION IF EXISTS public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer, text, boolean);

CREATE OR REPLACE FUNCTION public.popular_post_ids(
  p_query     text                 DEFAULT NULL,
  p_tags      text[]               DEFAULT NULL,
  p_branch    public.dental_branch DEFAULT NULL,
  p_now       timestamptz          DEFAULT now(),
  p_limit     integer              DEFAULT 20,
  p_offset    integer              DEFAULT 0,
  p_treatment text                 DEFAULT NULL,
  p_recent    boolean              DEFAULT false,
  p_type      public.post_type     DEFAULT NULL
)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH wanted AS (
    SELECT DISTINCT public.find_tag(public.tag_match_key(k)) AS id
      FROM unnest(coalesce(p_tags, '{}')) k
  ), q AS (
    SELECT public.search_tsquery(p_query) AS tsq
  )
  SELECT p.id
    FROM public.posts p, q
   WHERE NOT public.is_blocked_between((select auth.uid()), p.user_id)
     AND (q.tsq IS NULL OR p.search_vector @@ q.tsq)
     AND (p_type IS NULL OR p.type = p_type)
     AND (p.type <> 'listing' OR (NOT p.is_sold
           AND (q.tsq IS NOT NULL OR p_type IS NOT DISTINCT FROM 'listing')))
     AND (p_branch IS NULL OR EXISTS (
           SELECT 1 FROM public.post_treatments t
            WHERE t.post_id = p.id AND t.branch = p_branch))
     AND (p_treatment IS NULL OR EXISTS (
           SELECT 1 FROM public.post_treatments t
             JOIN public.tags g ON g.id = t.tag_id
            WHERE t.post_id = p.id AND g.slug = p_treatment))
     AND NOT EXISTS (
       SELECT 1 FROM wanted w
        WHERE w.id IS NULL
           OR NOT EXISTS (SELECT 1 FROM public.post_tags pt
                           WHERE pt.post_id = p.id AND pt.tag_id = w.id))
   ORDER BY extract(epoch FROM p.created_at) * p_recent::int DESC,
            (q.tsq IS NOT NULL AND ts_filter(p.search_vector, '{a}') @@ q.tsq) DESC,
            public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                  p.view_count, p_now - p.created_at) DESC,
            p.id
   LIMIT least(greatest(p_limit, 1), 50)
  OFFSET greatest(p_offset, 0);
$$;

REVOKE EXECUTE ON FUNCTION public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer, text, boolean, public.post_type)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer, text, boolean, public.post_type)
  TO authenticated;
