-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 038: Önek ve aksan duyarsız arama
-- ═══════════════════════════════════════════════════════════════════════════════
-- Sorun: plainto_tsquery tam sözcük ister ("umu" → "Umut Toker" bulunmaz),
--   Türkçe kök bulucu isimleri bozar, "ozturk" "Öztürk"ü bulmaz; kullanıcı
--   aramasında engellenen kullanıcılar da çıkıyordu.
-- search_fold: Türkçe harfleri ASCII'ye katlar (locale'den bağımsız; en_US'te
--   lower('I') 'ı' değil 'i' verir).
-- search_vector'lar: postlar Türkçe kök + katlanmış sözcük, kullanıcılar
--   yalnızca katlanmış sözcük (isim köklenmez).
-- search_tsquery: her sözcük önek (:*) olarak aranır, sözcükler AND'lenir.
-- popular_post_ids: başlıkta geçenler önce, sonra popülerlik.
-- search_user_ids: kullanıcı araması; kendini ve engellenenleri dışlar.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.search_fold(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = ''
AS $$
  SELECT lower(translate(coalesce(p_text, ''),
                         'İIıŞşĞğÜüÖöÇçÂâÎîÛû',
                         'iiissgguuooccaaiiuu'));
$$;

ALTER TABLE public.posts ALTER COLUMN search_vector SET EXPRESSION AS (
  setweight(to_tsvector('turkish', coalesce(title, '')), 'A') ||
  setweight(to_tsvector('simple', public.search_fold(title)), 'A') ||
  setweight(to_tsvector('turkish', coalesce(content, '')), 'B') ||
  setweight(to_tsvector('simple', public.search_fold(content)), 'B')
);

ALTER TABLE public.users ALTER COLUMN search_vector SET EXPRESSION AS (
  setweight(to_tsvector('simple', public.search_fold(full_name)), 'A') ||
  setweight(to_tsvector('simple', public.search_fold(username)), 'A') ||
  setweight(to_tsvector('simple', public.search_fold(university)), 'B')
);

-- Boş ya da yalnızca noktalama olan sorguda NULL döner.
CREATE OR REPLACE FUNCTION public.search_tsquery(p_query text, p_stem boolean DEFAULT true)
RETURNS tsquery
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_word   text;
  v_term   tsquery;
  v_result tsquery;
BEGIN
  FOR v_word IN
    SELECT w FROM regexp_split_to_table(coalesce(p_query, ''), '\s+') w WHERE w <> ''
  LOOP
    -- tsquery sözdizimine güvenli: tırnak ve ters bölü kaçırılır.
    v_term := to_tsquery('simple',
      '''' || replace(replace(public.search_fold(v_word), '\', '\\'), '''', '''''') || ''':*');
    IF p_stem THEN
      v_term := v_term || to_tsquery('turkish',
        '''' || replace(replace(v_word, '\', '\\'), '''', '''''') || ''':*');
    END IF;
    IF numnode(v_term) > 0 THEN
      v_result := coalesce(v_result && v_term, v_term);
    END IF;
  END LOOP;
  RETURN v_result;
END;
$$;

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
  ), q AS (
    SELECT public.search_tsquery(p_query) AS tsq
  )
  SELECT p.id
    FROM public.posts p, q
   WHERE NOT public.is_blocked_between((select auth.uid()), p.user_id)
     AND (q.tsq IS NULL OR p.search_vector @@ q.tsq)
     AND (p_branch IS NULL OR p.branch = p_branch)
     -- Bilinmeyen etiket (id NULL) sonucu boşaltır.
     AND NOT EXISTS (
       SELECT 1 FROM wanted w
        WHERE w.id IS NULL
           OR NOT EXISTS (SELECT 1 FROM public.post_tags pt
                           WHERE pt.post_id = p.id AND pt.tag_id = w.id))
   ORDER BY (q.tsq IS NOT NULL AND ts_filter(p.search_vector, '{a}') @@ q.tsq) DESC,
            public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                  p.view_count, p_now - p.created_at) DESC,
            p.id
   LIMIT least(greatest(p_limit, 1), 50)
  OFFSET greatest(p_offset, 0);
$$;

-- Invoker: users RLS geçerli; engel kontrolü is_blocked_between (definer) ile.
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
   -- Ad/kullanıcı adında geçenler üniversitede geçenlerden önce.
   ORDER BY ts_filter(u.search_vector, '{a}') @@ q.tsq DESC,
            ts_rank(u.search_vector, q.tsq) DESC,
            u.followers_count DESC,
            u.id
   LIMIT least(greatest(p_limit, 1), 50);
$$;

REVOKE EXECUTE ON FUNCTION public.search_tsquery(text, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.search_tsquery(text, boolean) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.search_user_ids(text, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.search_user_ids(text, integer) TO authenticated;
