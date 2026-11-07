-- ═══════════════════════════════════════════════════════════════════════════════
-- Dentigo — Migration 046: Gönderide video ve medya sıralama (vaka ve forum)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Bir gönderide en fazla 1 video (≤60 sn, istemcide 720p mp4'e sıkıştırılır).
-- Video da bir post_images satırıdır: image_url kapak resmi (post-images, JPEG),
-- video_path videonun kendisi (private post-videos bucket'ı). Böylece görsel ve
-- video tek sort_order ile sıralanır; sıra paylaşırken ve düzenlerken değişir.
-- Medya sınırı (video dahil): vaka 10, forum 4. Forumda görsel 015'ten beri vardı.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.post_images ADD COLUMN IF NOT EXISTS video_path text;
CREATE UNIQUE INDEX IF NOT EXISTS uq_post_images_one_video
  ON public.post_images (post_id) WHERE video_path IS NOT NULL;

-- ─── post-videos bucket (020 ile aynı model: okuma yalnızca oturum açmış) ─────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('post-videos', 'post-videos', false, 52428800, ARRAY['video/mp4'])
ON CONFLICT (id) DO UPDATE
  SET public = false, file_size_limit = 52428800, allowed_mime_types = ARRAY['video/mp4'];

DROP POLICY IF EXISTS "post_videos_read" ON storage.objects;
CREATE POLICY "post_videos_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'post-videos');

DROP POLICY IF EXISTS "post_videos_upload" ON storage.objects;
CREATE POLICY "post_videos_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-videos'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "post_videos_delete" ON storage.objects;
CREATE POLICY "post_videos_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'post-videos'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
  );

-- ─── create_post: p_video_path, p_video_index ────────────────────────────────
DROP FUNCTION IF EXISTS public.create_post(public.post_type, text, text, text[], jsonb, jsonb);

CREATE OR REPLACE FUNCTION public.create_post(
  p_type        public.post_type,
  p_title       text,
  p_content     text,
  p_image_paths text[]  DEFAULT '{}',   -- sıralı; videonun kapağı da burada
  p_tags        jsonb   DEFAULT '[]',   -- [{"name": "İmplant", "slug": "implant"}, …]
  p_treatments  jsonb   DEFAULT '[]',   -- vakada 1–5; biçim: resolve_case_treatments
  p_video_path  text    DEFAULT NULL,   -- post-videos içinde
  p_video_index integer DEFAULT NULL    -- kapağın p_image_paths'teki yeri (0'dan)
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
  IF (p_video_path IS NULL) <> (p_video_index IS NULL)
     OR p_video_index < 0 OR p_video_index >= cardinality(v_paths) THEN
    RAISE EXCEPTION 'invalid video index' USING ERRCODE = '22023';
  END IF;
  -- Her yol (kapak dahil), bu kullanıcının post-images'a yüklediği bir nesne olmalı.
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
  IF p_video_path IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM storage.objects o
     WHERE o.bucket_id = 'post-videos'
       AND o.name = p_video_path
       AND (storage.foldername(o.name))[1] = v_uid::text
  ) THEN
    RAISE EXCEPTION 'invalid video path' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.posts (user_id, type, title, content)
  VALUES (v_uid, p_type, v_title, v_content)
  RETURNING id INTO v_post_id;

  INSERT INTO public.post_images (post_id, image_url, sort_order)
  SELECT v_post_id, path, ord - 1
    FROM unnest(v_paths) WITH ORDINALITY AS t(path, ord);
  IF p_video_path IS NOT NULL THEN
    UPDATE public.post_images SET video_path = p_video_path
     WHERE post_id = v_post_id AND sort_order = p_video_index;
  END IF;

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

-- ─── update_post: p_media_order (medya eklenmez/silinmez, yalnızca sıralanır) ─
DROP FUNCTION IF EXISTS public.update_post(uuid, text, text, jsonb, jsonb);

CREATE OR REPLACE FUNCTION public.update_post(
  p_post_id     uuid,
  p_title       text,
  p_content     text,
  p_tags        jsonb  DEFAULT '[]',  -- create_post ile aynı biçim
  p_treatments  jsonb  DEFAULT '[]',
  p_media_order uuid[] DEFAULT NULL   -- post_images id'leri yeni sırayla; NULL: değişmez
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

  -- Sıra, postun bütün medyasını tam bir kez içermeli (eksik, fazla, tekrar yok).
  IF p_media_order IS NOT NULL THEN
    IF cardinality(p_media_order) <> (SELECT count(*) FROM public.post_images WHERE post_id = p_post_id)
       OR cardinality(p_media_order) <> (SELECT count(DISTINCT x) FROM unnest(p_media_order) AS x)
       OR EXISTS (
         SELECT 1 FROM unnest(p_media_order) AS x
          WHERE NOT EXISTS (SELECT 1 FROM public.post_images
                             WHERE id = x AND post_id = p_post_id)
       ) THEN
      RAISE EXCEPTION 'invalid media order' USING ERRCODE = '22023';
    END IF;
    UPDATE public.post_images i SET sort_order = t.ord - 1
      FROM unnest(p_media_order) WITH ORDINALITY AS t(id, ord)
     WHERE i.id = t.id;
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

REVOKE EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, text[], jsonb, jsonb, text, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, text[], jsonb, jsonb, text, integer) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.update_post(uuid, text, text, jsonb, jsonb, uuid[]) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.update_post(uuid, text, text, jsonb, jsonb, uuid[]) TO authenticated;
