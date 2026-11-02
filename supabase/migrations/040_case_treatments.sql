-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 040: Çoklu tedavi ve tedavi arşivi
-- ═══════════════════════════════════════════════════════════════════════════════
-- Vakada 1–5 tedavi seçilir; ana/ek ayrımı yok, sıra seçim sırası. Tedavinin
-- kimliği etiketidir: listedeki tedavi (treatment_types) de kullanıcının
-- eklediği tedavi de bir etiket. Listedekinin branşı sabit; kullanıcının
-- eklediğinde branşı kullanıcı seçer. Branş filtresi vakanın bütün tedavi
-- branşlarına bakar. posts.treatment / other_treatment_tag_id (033, 034) ve
-- "Diğer" akışı (case_treatment) kalkar; mevcut vakalar post_treatments'a taşınır.
-- Tedavi etiketleri post_tags'te de durur (#etiket araması, popüler konular)
-- ama 5 serbest etiket sınırına sayılmaz.
-- posts.branch: ilk tedavinin branşı (başlıktaki branş adı için).
-- Uygulama yayında değil: eski istemci uyumluluğu (expand/contract) gerekmiyor.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.post_treatments (
  post_id  uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  tag_id   uuid NOT NULL REFERENCES public.tags(id),
  branch   public.dental_branch NOT NULL
           CONSTRAINT post_treatments_branch_not_removed
           CHECK (branch <> 'oral_diagnoz_uzmani'),
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 4),
  PRIMARY KEY (post_id, tag_id)
);
CREATE INDEX IF NOT EXISTS idx_post_treatments_tag_id ON public.post_treatments (tag_id);
CREATE INDEX IF NOT EXISTS idx_post_treatments_branch ON public.post_treatments (branch);

-- Okuma serbest (post_tags gibi; görünürlük posts RLS'inde). Yazma yalnızca RPC.
ALTER TABLE public.post_treatments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "post_treatments_select_all" ON public.post_treatments;
CREATE POLICY "post_treatments_select_all" ON public.post_treatments
  FOR SELECT TO authenticated USING (true);
REVOKE ALL ON public.post_treatments FROM public, anon, authenticated;
GRANT SELECT ON public.post_treatments TO authenticated;

-- ─── Mevcut vakalar ──────────────────────────────────────────────────────────
INSERT INTO public.post_treatments (post_id, tag_id, branch, position)
SELECT p.id, coalesce(tt.tag_id, p.other_treatment_tag_id), p.branch, 0
  FROM public.posts p
  LEFT JOIN public.treatment_types tt ON tt.code = p.treatment
 WHERE p.type = 'case'
   AND p.branch IS NOT NULL
   AND coalesce(tt.tag_id, p.other_treatment_tag_id) IS NOT NULL
ON CONFLICT DO NOTHING;

-- ─── Eski tek tedavi yapısı ──────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb, text, text);
DROP FUNCTION IF EXISTS public.update_post(uuid, text, text, public.dental_branch, jsonb, text, text);
DROP FUNCTION IF EXISTS public.case_treatment(public.dental_branch, text, text);
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_other_treatment_check;
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_treatment_case_only;
DROP INDEX IF EXISTS public.idx_posts_other_treatment_tag_id;
ALTER TABLE public.posts DROP COLUMN IF EXISTS other_treatment_tag_id;
ALTER TABLE public.posts DROP COLUMN IF EXISTS treatment;

-- ─── 5 etiket sınırı (017): tedavi etiketleri sayılmaz ───────────────────────
CREATE OR REPLACE FUNCTION public.limit_post_tags()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.post_treatments t
              WHERE t.post_id = NEW.post_id AND t.tag_id = NEW.tag_id) THEN
    RETURN NEW;
  END IF;
  IF (SELECT count(*) FROM public.post_tags pt
       WHERE pt.post_id = NEW.post_id
         AND NOT EXISTS (SELECT 1 FROM public.post_treatments t
                          WHERE t.post_id = pt.post_id AND t.tag_id = pt.tag_id)) >= 5 THEN
    RAISE EXCEPTION 'too many tags' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

-- ─── merge_tags (032, 034): tedavi bağını da taşır ───────────────────────────
CREATE OR REPLACE FUNCTION public.merge_tags(p_from uuid, p_into uuid)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF p_from = p_into THEN
    RETURN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tags WHERE id = p_into) THEN
    RAISE EXCEPTION 'merge target not found' USING ERRCODE = 'P0002';
  END IF;

  -- Önce tedaviler: post_tags taşınırken limit trigger'ı tedaviyi tanısın.
  UPDATE public.post_treatments SET tag_id = p_into
   WHERE tag_id = p_from
     AND post_id NOT IN (SELECT post_id FROM public.post_treatments WHERE tag_id = p_into);
  DELETE FROM public.post_treatments WHERE tag_id = p_from;

  UPDATE public.post_tags SET tag_id = p_into
   WHERE tag_id = p_from
     AND post_id NOT IN (SELECT post_id FROM public.post_tags WHERE tag_id = p_into);
  DELETE FROM public.post_tags WHERE tag_id = p_from;

  UPDATE public.tag_aliases SET tag_id = p_into WHERE tag_id = p_from;
  INSERT INTO public.tag_aliases (match_key, tag_id)
  SELECT f.match_key, p_into
    FROM public.tags f, public.tags i
   WHERE f.id = p_from AND i.id = p_into AND f.match_key <> i.match_key
  ON CONFLICT (match_key) DO UPDATE SET tag_id = EXCLUDED.tag_id;

  DELETE FROM public.tags WHERE id = p_from;
  UPDATE public.tags
     SET usage_count = (SELECT count(*) FROM public.post_tags WHERE tag_id = p_into)
   WHERE id = p_into;
END;
$$;

-- ─── Tedavileri çözme ────────────────────────────────────────────────────────
-- p_treatments: [{"name": "kanal-tedavisi", "slug": "kanal-tedavisi"},
--                {"name": "zirkonya-inley", "slug": "zirkonya-inley", "branch": "protez_uzmani"}]
-- Ad etiket sisteminden geçer (yazım farkı, eş anlamlı, çoğul). Listedeki bir
-- tedaviye çözülürse branşı listeden gelir; değilse "branch" zorunlu.
-- Tekrarlar atlanır; sıra korunur. 1–5 tedavi, aksi 22023.
CREATE OR REPLACE FUNCTION public.resolve_case_treatments(p_treatments jsonb)
RETURNS TABLE (o_tag uuid, o_branch public.dental_branch, o_pos smallint)
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_item   jsonb;
  v_tag    uuid;
  v_branch public.dental_branch;
  v_text   text;
  v_seen   uuid[] := '{}';
BEGIN
  IF jsonb_typeof(p_treatments) IS DISTINCT FROM 'array'
     OR jsonb_array_length(p_treatments) NOT BETWEEN 1 AND 5 THEN
    RAISE EXCEPTION 'case needs 1-5 treatments' USING ERRCODE = '22023';
  END IF;
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_treatments) LOOP
    v_tag := (public.resolve_tags(jsonb_build_array(v_item)))[1];
    IF v_tag IS NULL THEN
      RAISE EXCEPTION 'invalid treatment' USING ERRCODE = '22023';
    END IF;
    SELECT t.branch INTO v_branch FROM public.treatment_types t WHERE t.tag_id = v_tag;
    IF NOT FOUND THEN
      v_text := v_item->>'branch';
      IF v_text IS NULL OR v_text = 'oral_diagnoz_uzmani'
         OR NOT v_text = ANY (enum_range(NULL::public.dental_branch)::text[]) THEN
        RAISE EXCEPTION 'invalid treatment branch' USING ERRCODE = '22023';
      END IF;
      v_branch := v_text::public.dental_branch;
    END IF;
    CONTINUE WHEN v_tag = ANY (v_seen);
    v_seen := v_seen || v_tag;
    o_tag := v_tag;
    o_branch := v_branch;
    o_pos := cardinality(v_seen) - 1;
    RETURN NEXT;
  END LOOP;
END;
$$;

-- Postun tedavilerini yazar (eskiler silinir), ilk tedavinin branşını döner.
-- Etiketleri post_tags'e ekleme çağıranın işi (serbest etiketlerle birlikte).
CREATE OR REPLACE FUNCTION public.set_post_treatments(p_post_id uuid, p_treatments jsonb)
RETURNS public.dental_branch
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_first public.dental_branch;
BEGIN
  DELETE FROM public.post_treatments WHERE post_id = p_post_id;
  INSERT INTO public.post_treatments (post_id, tag_id, branch, position)
  SELECT p_post_id, r.o_tag, r.o_branch, r.o_pos
    FROM public.resolve_case_treatments(p_treatments) r;
  SELECT branch INTO v_first FROM public.post_treatments
   WHERE post_id = p_post_id ORDER BY position LIMIT 1;
  RETURN v_first;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.resolve_case_treatments(jsonb),
  public.set_post_treatments(uuid, jsonb)
  FROM public, anon, authenticated;

-- ─── create_post / update_post: p_treatments ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_post(
  p_type        public.post_type,
  p_title       text,
  p_content     text,
  p_image_paths text[] DEFAULT '{}',
  p_tags        jsonb  DEFAULT '[]',  -- [{"name": "İmplant", "slug": "implant"}, …]
  p_treatments  jsonb  DEFAULT '[]'   -- vakada 1–5; biçim: resolve_case_treatments
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_title   text := btrim(p_title);
  v_content text := btrim(p_content);
  v_paths   text[] := coalesce(p_image_paths, '{}');
  v_tag_ids uuid[];
  v_post_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF v_title IS NULL OR v_title = '' OR v_content IS NULL OR v_content = '' THEN
    RAISE EXCEPTION 'title and content required' USING ERRCODE = '22023';
  END IF;
  -- CASE…END kullanılmıyor: CLI'ın SQL bölücüsü fonksiyon gövdesinde onu yanlış ayırıyor.
  IF cardinality(v_paths) > 10 OR (p_type = 'question' AND cardinality(v_paths) > 4) THEN
    RAISE EXCEPTION 'too many images' USING ERRCODE = '22023';
  END IF;
  -- Her yol, bu kullanıcının post-images'a yüklediği bir nesne olmalı.
  IF EXISTS (
    SELECT 1 FROM unnest(v_paths) AS p(path)
     WHERE NOT EXISTS (
       SELECT 1 FROM storage.objects o
        WHERE o.bucket_id = 'post-images'
          AND o.name = p.path
          AND (storage.foldername(o.name))[1] = v_uid::text
     )
  ) THEN
    RAISE EXCEPTION 'invalid image path' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.posts (user_id, type, title, content)
  VALUES (v_uid, p_type, v_title, v_content)
  RETURNING id INTO v_post_id;

  INSERT INTO public.post_images (post_id, image_url, sort_order)
  SELECT v_post_id, path, ord - 1
    FROM unnest(v_paths) WITH ORDINALITY AS t(path, ord);

  -- Tedaviler yalnızca vakada. Görsel kontrolünden sonra: yeni etiket açabilir.
  IF p_type = 'case' THEN
    UPDATE public.posts SET branch = public.set_post_treatments(v_post_id, p_treatments)
     WHERE id = v_post_id;
  END IF;

  -- Tedavi etiketleri önce; serbest etiketler sınıra (5) onlarsız sayılır.
  v_tag_ids := ARRAY(SELECT tag_id FROM public.post_treatments
                      WHERE post_id = v_post_id ORDER BY position)
               || public.resolve_tags(p_tags);
  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT v_post_id, tag_id FROM unnest(v_tag_ids) AS tag_id
  ON CONFLICT DO NOTHING;

  RETURN v_post_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_post(
  p_post_id    uuid,
  p_title      text,
  p_content    text,
  p_tags       jsonb DEFAULT '[]',  -- create_post ile aynı biçim
  p_treatments jsonb DEFAULT '[]'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_title   text := btrim(p_title);
  v_content text := btrim(p_content);
  v_type    public.post_type;
  v_tag_ids uuid[];
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT type INTO v_type FROM public.posts
   WHERE id = p_post_id AND user_id = v_uid
   FOR UPDATE;
  IF NOT FOUND THEN
    -- Yok ya da başkasının: ikisi de istemcide "bulunamadı".
    RAISE EXCEPTION 'post not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_title IS NULL OR v_title = '' OR v_content IS NULL OR v_content = '' THEN
    RAISE EXCEPTION 'title and content required' USING ERRCODE = '22023';
  END IF;

  UPDATE public.posts SET title = v_title, content = v_content WHERE id = p_post_id;
  IF v_type = 'case' THEN
    UPDATE public.posts SET branch = public.set_post_treatments(p_post_id, p_treatments)
     WHERE id = p_post_id;
  END IF;

  -- Etiketler: yeni sette olmayan bağlar silinir, yeniler eklenir.
  v_tag_ids := ARRAY(SELECT tag_id FROM public.post_treatments
                      WHERE post_id = p_post_id ORDER BY position)
               || public.resolve_tags(p_tags);
  DELETE FROM public.post_tags
   WHERE post_id = p_post_id AND tag_id <> ALL (v_tag_ids);
  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT p_post_id, tag_id FROM unnest(v_tag_ids) AS tag_id
  ON CONFLICT DO NOTHING;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, text[], jsonb, jsonb) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, text[], jsonb, jsonb) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.update_post(uuid, text, text, jsonb, jsonb) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.update_post(uuid, text, text, jsonb, jsonb) TO authenticated;

-- ─── promote_other_treatment (034): kullanıcı tedavisini listeye alır ────────
-- Vakalar zaten etiketle bağlı; yalnızca branşları listedekine eşitlenir.
-- Dönen değer: branşı düzeltilen vaka sayısı.
CREATE OR REPLACE FUNCTION public.promote_other_treatment(p_tag text, p_branch public.dental_branch)
RETURNS integer
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_tag  uuid;
  v_code text;
  v_n    integer;
BEGIN
  SELECT id, slug INTO v_tag, v_code FROM public.tags
   WHERE match_key = public.tag_match_key(p_tag);
  IF v_tag IS NULL THEN
    RAISE EXCEPTION 'tag % not found', p_tag;
  END IF;
  UPDATE public.tags SET is_curated = true WHERE id = v_tag;
  INSERT INTO public.treatment_types (code, branch, tag_id) VALUES (v_code, p_branch, v_tag);
  UPDATE public.post_treatments SET branch = p_branch
   WHERE tag_id = v_tag AND branch <> p_branch;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.promote_other_treatment(text, public.dental_branch)
  FROM public, anon, authenticated;

-- ─── Keşfet / arşiv listesi: tedavi filtresi ve "en yeni" sırası ────────────
DROP FUNCTION IF EXISTS public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer);

-- p_treatment: tedavi etiketinin slug'ı (yalnızca o tedavinin vakaları).
-- p_recent: popülerlik yerine en yeni önce.
CREATE OR REPLACE FUNCTION public.popular_post_ids(
  p_query     text                 DEFAULT NULL,
  p_tags      text[]               DEFAULT NULL,
  p_branch    public.dental_branch DEFAULT NULL,
  p_now       timestamptz          DEFAULT now(),
  p_limit     integer              DEFAULT 20,
  p_offset    integer              DEFAULT 0,
  p_treatment text                 DEFAULT NULL,
  p_recent    boolean              DEFAULT false
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
     -- Vaka, tedavilerinin bütün branşlarında görünür.
     AND (p_branch IS NULL OR EXISTS (
           SELECT 1 FROM public.post_treatments t
            WHERE t.post_id = p.id AND t.branch = p_branch))
     AND (p_treatment IS NULL OR EXISTS (
           SELECT 1 FROM public.post_treatments t
             JOIN public.tags g ON g.id = t.tag_id
            WHERE t.post_id = p.id AND g.slug = p_treatment))
     -- Bilinmeyen etiket (id NULL) sonucu boşaltır.
     AND NOT EXISTS (
       SELECT 1 FROM wanted w
        WHERE w.id IS NULL
           OR NOT EXISTS (SELECT 1 FROM public.post_tags pt
                           WHERE pt.post_id = p.id AND pt.tag_id = w.id))
   -- CASE yok (bkz. create_post): p_recent false iken ilk anahtar hep 0.
   ORDER BY extract(epoch FROM p.created_at) * p_recent::int DESC,
            (q.tsq IS NOT NULL AND ts_filter(p.search_vector, '{a}') @@ q.tsq) DESC,
            public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                  p.view_count, p_now - p.created_at) DESC,
            p.id
   LIMIT least(greatest(p_limit, 1), 50)
  OFFSET greatest(p_offset, 0);
$$;

REVOKE EXECUTE ON FUNCTION public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer, text, boolean)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_post_ids(text, text[], public.dental_branch, timestamptz, integer, integer, text, boolean)
  TO authenticated;

-- ─── Tedavi listesi: Keşfet branş satırı, arama, arşiv başlığı, seçim penceresi ─
-- Listedeki tedaviler (vakası olmasa da) + en az bir vakada geçen kullanıcı
-- tedavileri; (etiket, branş) başına bir satır ve vaka sayısı.
-- p_query: ad ya da eş anlamlı içinde arar, baştan eşleşen önce.
-- shortcut: sayılar engellenen kullanıcıların vakalarını da sayar ve her
--   çağrıda post_treatments baştan gruplanır; on binlerce vakada sayaç kolonuna geç.
CREATE OR REPLACE FUNCTION public.list_treatments(
  p_branch public.dental_branch DEFAULT NULL,
  p_query  text                 DEFAULT NULL,
  p_slug   text                 DEFAULT NULL,
  p_limit  integer              DEFAULT 50
)
RETURNS TABLE (slug text, name text, branch public.dental_branch, case_count integer)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH stats AS (
    SELECT pt.tag_id, pt.branch, count(*)::int AS n
      FROM public.post_treatments pt
     GROUP BY pt.tag_id, pt.branch
  ), pool AS (
    SELECT tt.tag_id, tt.branch, coalesce(s.n, 0) AS n
      FROM public.treatment_types tt
      LEFT JOIN stats s ON s.tag_id = tt.tag_id AND s.branch = tt.branch
     WHERE tt.branch <> 'oral_diagnoz_uzmani'
    UNION ALL
    SELECT s.tag_id, s.branch, s.n
      FROM stats s
     WHERE NOT EXISTS (SELECT 1 FROM public.treatment_types tt WHERE tt.tag_id = s.tag_id)
  ), q AS (
    SELECT nullif(public.tag_match_key(coalesce(p_query, '')), '') AS k
  )
  SELECT t.slug, t.name, r.branch, r.n
    FROM pool r
    JOIN public.tags t ON t.id = r.tag_id, q
   WHERE (p_branch IS NULL OR r.branch = p_branch)
     AND (p_slug IS NULL OR t.slug = p_slug)
     AND (q.k IS NULL
          OR t.match_key LIKE '%' || q.k || '%'
          OR EXISTS (SELECT 1 FROM public.tag_aliases a
                      WHERE a.tag_id = r.tag_id AND a.match_key LIKE q.k || '%'))
   ORDER BY (q.k IS NOT NULL AND t.match_key LIKE q.k || '%') DESC, r.n DESC, t.name
   LIMIT least(greatest(p_limit, 1), 100);
$$;

REVOKE EXECUTE ON FUNCTION public.list_treatments(public.dental_branch, text, text, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.list_treatments(public.dental_branch, text, text, integer) TO authenticated;

-- ─── Benzer vakalar: ortak tedavisi en çok olan önce, sonra en yeni ──────────
CREATE OR REPLACE FUNCTION public.related_case_ids(p_post_id uuid, p_limit integer DEFAULT 10)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p.id
    FROM public.post_treatments mine
    JOIN public.post_treatments o ON o.tag_id = mine.tag_id AND o.post_id <> mine.post_id
    JOIN public.posts p ON p.id = o.post_id
   WHERE mine.post_id = p_post_id
     AND NOT public.is_blocked_between((select auth.uid()), p.user_id)
   GROUP BY p.id
   ORDER BY count(*) DESC, max(p.created_at) DESC, p.id
   LIMIT least(greatest(p_limit, 1), 20);
$$;

REVOKE EXECUTE ON FUNCTION public.related_case_ids(uuid, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.related_case_ids(uuid, integer) TO authenticated;
