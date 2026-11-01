-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 035: Keşfet popülerlik sıralaması
-- ═══════════════════════════════════════════════════════════════════════════════
-- post_hot_score: etkileşim / yaş^1.5 (Hacker News "gravity" kalıbı). Etkileşim
--   beğeni + 2×yorum + 2×kaydetme + 0.05×görüntülenme + 1; yaş saat cinsinden +2.
--   Yeni post etkileşimsiz de bir süre üstte kalır, eski post ancak çok
--   etkileşimle yeni postu geçer.
-- popular_post_ids: Keşfet listesi. Metin (Türkçe FTS), etiketler (hepsi
--   bulunmalı; eş anlamlılar asıl etikete çözülür) ve branşla filtreler,
--   skora göre sıralar. Postlar istemcide normal select ile çekilir (RLS orada
--   da geçerli). p_now sayfalar arasında sabit tutulur ki skor kaymasın.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.post_hot_score(
  p_likes     integer,
  p_comments  integer,
  p_bookmarks integer,
  p_views     integer,
  p_age       interval
)
RETURNS double precision
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT (p_likes + 2 * p_comments + 2 * p_bookmarks + 0.05 * p_views + 1)::float8
       / power(greatest(extract(epoch FROM p_age)::float8 / 3600, 0) + 2, 1.5);
$$;

-- shortcut: skor index'lenemez, filtreye uyan tüm postlar taranıp sıralanır ve
-- OFFSET sayfalar arası sayaç değişiminde kayabilir; on binlerce postta
-- skoru periyodik hesaplanan bir kolona taşı.
CREATE OR REPLACE FUNCTION public.popular_post_ids(
  p_query  text                 DEFAULT NULL,
  p_tags   text[]               DEFAULT NULL,
  p_branch public.dental_branch DEFAULT NULL,
  p_now    timestamptz          DEFAULT now(),
  p_limit  integer              DEFAULT 20,
  p_offset integer              DEFAULT 0
)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
-- tag_aliases istemciye kapalı (032); engel filtresi aşağıda elle uygulanır.
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH wanted AS (
    SELECT DISTINCT public.find_tag(public.tag_match_key(k)) AS id
      FROM unnest(coalesce(p_tags, '{}')) k
  )
  SELECT p.id
    FROM public.posts p
   WHERE NOT public.is_blocked_between((select auth.uid()), p.user_id)
     AND (nullif(btrim(p_query), '') IS NULL
          OR p.search_vector @@ plainto_tsquery('turkish', p_query))
     AND (p_branch IS NULL OR p.branch = p_branch)
     -- Bilinmeyen etiket (id NULL) sonucu boşaltır.
     AND NOT EXISTS (
       SELECT 1 FROM wanted w
        WHERE w.id IS NULL
           OR NOT EXISTS (SELECT 1 FROM public.post_tags pt
                           WHERE pt.post_id = p.id AND pt.tag_id = w.id))
   ORDER BY public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                  p.view_count, p_now - p.created_at) DESC,
            p.id
   LIMIT least(greatest(p_limit, 1), 50)
  OFFSET greatest(p_offset, 0);
$$;

REVOKE EXECUTE ON FUNCTION public.post_hot_score(integer, integer, integer, integer, interval)
  FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer)
  TO authenticated;
