-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 015: create_post RPC (DATA-4, SEC-13)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Post, görsel kayıtları ve etiketler tek işlemde. İstemci önce görselleri
-- kendi klasörüne yükler, sonra yolları bu RPC'ye verir; RPC hata verirse
-- istemci yüklediklerini siler. Yarım post, yanlış posts_count kalmaz.
-- post_images.image_url artık tam URL değil, bucket içi yol (<uid>/<dosya>);
-- yalnızca kullanıcının gerçekten yüklediği nesneler kabul edilir.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.create_post(
  p_type        public.post_type,
  p_title       text,
  p_content     text,
  p_branch      public.dental_branch DEFAULT NULL,
  p_image_paths text[] DEFAULT '{}',
  p_tags        jsonb  DEFAULT '[]'   -- [{"name": "İmplant", "slug": "implant"}, …]
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
  v_branch  public.dental_branch;
  v_post_id uuid;
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
  -- Branş yalnızca vakada tutulur.
  IF p_type = 'case' THEN
    v_branch := p_branch;
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

  INSERT INTO public.posts (user_id, type, title, content, branch)
  VALUES (v_uid, p_type, v_title, v_content, v_branch)
  RETURNING id INTO v_post_id;

  INSERT INTO public.post_images (post_id, image_url, sort_order)
  SELECT v_post_id, path, ord - 1
    FROM unnest(v_paths) WITH ORDINALITY AS t(path, ord);

  -- Var olan etiketlere dokunulmaz (ad ya da slug çakışırsa atla).
  INSERT INTO public.tags (name, slug)
  SELECT btrim(t->>'name'), t->>'slug'
    FROM jsonb_array_elements(coalesce(p_tags, '[]')) AS t
   WHERE t->>'slug' ~ '^[a-z0-9]+(-[a-z0-9]+)*$'
     AND btrim(t->>'name') <> ''
  ON CONFLICT DO NOTHING;

  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT v_post_id, tg.id
    FROM public.tags tg
   WHERE tg.slug IN (SELECT t->>'slug' FROM jsonb_array_elements(coalesce(p_tags, '[]')) AS t)
  ON CONFLICT DO NOTHING;

  RETURN v_post_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb) TO authenticated;

-- Oluşturma yalnızca RPC ile. Silme yetkileri (post sahibi) kalır.
REVOKE INSERT ON public.posts, public.post_images, public.post_tags, public.tags FROM authenticated;
DROP POLICY IF EXISTS "post_images_insert_own" ON public.post_images;
DROP POLICY IF EXISTS "post_tags_insert_own" ON public.post_tags;
DROP POLICY IF EXISTS "tags_insert_auth" ON public.tags;
DROP POLICY IF EXISTS "posts_insert_own" ON public.posts;

-- Eski kayıtlar: tam public URL → bucket içi yol.
UPDATE public.post_images
   SET image_url = regexp_replace(image_url, '^.*/storage/v1/object/public/post-images/', '')
 WHERE image_url LIKE '%/storage/v1/object/public/post-images/%';
