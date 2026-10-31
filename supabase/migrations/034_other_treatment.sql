-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 034: "Diğer" tedavi türü
-- ═══════════════════════════════════════════════════════════════════════════════
-- Listede olmayan tedavi: kullanıcı tedavi adını yazar (zorunlu). Ad etiket
-- sisteminden geçer (resolve_tags: yazım farkı, eş anlamlı, çoğul) ve posta
-- sabit etiket olur; posts.other_treatment_tag_id hangi etiket olduğunu tutar.
-- Yazılan ad bu branşın listedeki bir tedavisine çözülürse o tür seçilir.
-- Sık yazılan adlar promote_other_treatment ile listeye alınır (SUPABASE.md §9).
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS other_treatment_tag_id uuid REFERENCES public.tags(id);
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_other_treatment_check;
ALTER TABLE public.posts ADD CONSTRAINT posts_other_treatment_check
  CHECK (other_treatment_tag_id IS NULL OR (treatment IS NULL AND type = 'case'));
CREATE INDEX IF NOT EXISTS idx_posts_other_treatment_tag_id
  ON public.posts (other_treatment_tag_id) WHERE other_treatment_tag_id IS NOT NULL;

-- merge_tags (032) "diğer" tedavi bağını da taşır; yoksa FK birleştirmeyi engeller.
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

  UPDATE public.post_tags SET tag_id = p_into
   WHERE tag_id = p_from
     AND post_id NOT IN (SELECT post_id FROM public.post_tags WHERE tag_id = p_into);
  DELETE FROM public.post_tags WHERE tag_id = p_from;
  UPDATE public.posts SET other_treatment_tag_id = p_into WHERE other_treatment_tag_id = p_from;

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

-- Vakanın tedavisi: listeden kod ya da "diğer" adı. Sabit etiketi ve
-- (diğer ise) etiket bağını döner; geçersizse 22023.
CREATE OR REPLACE FUNCTION public.case_treatment(
  p_branch    public.dental_branch,
  p_treatment text,
  p_other     text,
  OUT o_code      text,
  OUT o_other_tag uuid,
  OUT o_fixed_tag uuid
)
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_slug text := public.tag_slug(coalesce(p_other, ''));
BEGIN
  IF v_slug <> '' THEN
    o_fixed_tag := (public.resolve_tags(jsonb_build_array(
      jsonb_build_object('name', btrim(p_other), 'slug', v_slug))))[1];
    -- Listede olan bir tedavi yazıldıysa ("rct") o tür seçilir.
    SELECT t.code INTO o_code FROM public.treatment_types t
     WHERE t.tag_id = o_fixed_tag AND t.branch = p_branch;
    IF o_code IS NULL THEN
      o_other_tag := o_fixed_tag;
    END IF;
  ELSE
    SELECT t.code, t.tag_id INTO o_code, o_fixed_tag FROM public.treatment_types t
     WHERE t.code = p_treatment AND t.branch = p_branch;
  END IF;
  IF o_fixed_tag IS NULL THEN
    RAISE EXCEPTION 'invalid treatment' USING ERRCODE = '22023';
  END IF;
END;
$$;

-- Sık yazılan "diğer" adını bu branşın tedavi türü yapar; o branşta bu adla
-- açılmış vakaları türe taşır, taşınan vaka sayısını döner. Kod = etiketin slug'ı.
-- Bir migration'da çağrılır ve istemcide TreatmentType + ARB ile birlikte yayınlanır.
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
  UPDATE public.posts SET treatment = v_code, other_treatment_tag_id = NULL
   WHERE other_treatment_tag_id = v_tag AND branch = p_branch;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.case_treatment(public.dental_branch, text, text),
  public.promote_other_treatment(text, public.dental_branch)
  FROM public, anon, authenticated;

-- ─── create_post / update_post: p_other_treatment ────────────────────────────
DROP FUNCTION IF EXISTS public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb, text);
DROP FUNCTION IF EXISTS public.update_post(uuid, text, text, public.dental_branch, jsonb, text);

CREATE OR REPLACE FUNCTION public.create_post(
  p_type            public.post_type,
  p_title           text,
  p_content         text,
  p_branch          public.dental_branch DEFAULT NULL,
  p_image_paths     text[] DEFAULT '{}',
  p_tags            jsonb  DEFAULT '[]',  -- [{"name": "İmplant", "slug": "implant"}, …]
  p_treatment       text   DEFAULT NULL,  -- treatment_types.code
  p_other_treatment text   DEFAULT NULL   -- "Diğer": tedavi adı; vakada biri zorunlu
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid       uuid := auth.uid();
  v_title     text := btrim(p_title);
  v_content   text := btrim(p_content);
  v_paths     text[] := coalesce(p_image_paths, '{}');
  v_branch    public.dental_branch;
  v_treatment text;
  v_other_tag uuid;
  v_fixed_tag uuid;
  v_tag_ids   uuid[];
  v_post_id   uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF v_title IS NULL OR v_title = '' OR v_content IS NULL OR v_content = '' THEN
    RAISE EXCEPTION 'title and content required' USING ERRCODE = '22023';
  END IF;
  IF p_type = 'case' AND p_branch IS NULL THEN
    RAISE EXCEPTION 'branch required for case' USING ERRCODE = '22023';
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
  -- Branş ve tedavi yalnızca vakada tutulur. Görsel kontrolünden sonra:
  -- "diğer" adı yeni etiket açabilir.
  IF p_type = 'case' THEN
    v_branch := p_branch;
    SELECT o_code, o_other_tag, o_fixed_tag INTO v_treatment, v_other_tag, v_fixed_tag
      FROM public.case_treatment(p_branch, p_treatment, p_other_treatment);
  END IF;

  INSERT INTO public.posts (user_id, type, title, content, branch, treatment, other_treatment_tag_id)
  VALUES (v_uid, p_type, v_title, v_content, v_branch, v_treatment, v_other_tag)
  RETURNING id INTO v_post_id;

  INSERT INTO public.post_images (post_id, image_url, sort_order)
  SELECT v_post_id, path, ord - 1
    FROM unnest(v_paths) WITH ORDINALITY AS t(path, ord);

  -- Tedavinin etiketi her zaman var (5 etiket sınırına dahil).
  v_tag_ids := public.resolve_tags(p_tags);
  IF v_fixed_tag IS NOT NULL THEN
    v_tag_ids := v_fixed_tag || array_remove(v_tag_ids, v_fixed_tag);
  END IF;
  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT v_post_id, tag_id FROM unnest(v_tag_ids) AS tag_id
  ON CONFLICT DO NOTHING;

  RETURN v_post_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_post(
  p_post_id         uuid,
  p_title           text,
  p_content         text,
  p_branch          public.dental_branch DEFAULT NULL,
  p_tags            jsonb DEFAULT '[]',  -- create_post ile aynı biçim
  p_treatment       text  DEFAULT NULL,
  p_other_treatment text  DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid       uuid := auth.uid();
  v_title     text := btrim(p_title);
  v_content   text := btrim(p_content);
  v_type      public.post_type;
  v_branch    public.dental_branch;
  v_treatment text;
  v_other_tag uuid;
  v_fixed_tag uuid;
  v_tag_ids   uuid[];
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
  IF v_type = 'case' AND p_branch IS NULL THEN
    RAISE EXCEPTION 'branch required for case' USING ERRCODE = '22023';
  END IF;
  -- Branş ve tedavi yalnızca vakada tutulur. (CASE…END yok: bkz. SUPABASE.md)
  IF v_type = 'case' THEN
    v_branch := p_branch;
    SELECT o_code, o_other_tag, o_fixed_tag INTO v_treatment, v_other_tag, v_fixed_tag
      FROM public.case_treatment(p_branch, p_treatment, p_other_treatment);
  END IF;

  UPDATE public.posts
     SET title = v_title, content = v_content, branch = v_branch,
         treatment = v_treatment, other_treatment_tag_id = v_other_tag
   WHERE id = p_post_id;

  -- Etiketler: yeni sette olmayan bağlar silinir, yeniler eklenir.
  v_tag_ids := public.resolve_tags(p_tags);
  IF v_fixed_tag IS NOT NULL THEN
    v_tag_ids := v_fixed_tag || array_remove(v_tag_ids, v_fixed_tag);
  END IF;
  DELETE FROM public.post_tags
   WHERE post_id = p_post_id AND tag_id <> ALL (v_tag_ids);
  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT p_post_id, tag_id FROM unnest(v_tag_ids) AS tag_id
  ON CONFLICT DO NOTHING;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb, text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.update_post(uuid, text, text, public.dental_branch, jsonb, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.update_post(uuid, text, text, public.dental_branch, jsonb, text, text) TO authenticated;
