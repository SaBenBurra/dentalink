-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 016: update_post RPC (post düzenleme)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Başlık, içerik, branş ve etiketler tek işlemde güncellenir. Etiket bağları
-- 015'ten beri yalnızca RPC ile yazılabildiği için düzenleme de RPC'dir.
-- Görseller düzenlenmez. tags.usage_count, post_tags trigger'ı ile güncellenir.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.update_post(
  p_post_id uuid,
  p_title   text,
  p_content text,
  p_branch  public.dental_branch DEFAULT NULL,
  p_tags    jsonb DEFAULT '[]'   -- create_post ile aynı biçim
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
  v_branch  public.dental_branch;
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
  -- Branş yalnızca vakada tutulur. (CASE…END yok: bkz. SUPABASE.md)
  IF v_type = 'case' THEN
    v_branch := p_branch;
  END IF;

  UPDATE public.posts
     SET title = v_title, content = v_content, branch = v_branch
   WHERE id = p_post_id;

  -- Etiketler: yeni sette olmayan bağlar silinir, yeniler eklenir.
  INSERT INTO public.tags (name, slug)
  SELECT btrim(t->>'name'), t->>'slug'
    FROM jsonb_array_elements(coalesce(p_tags, '[]')) AS t
   WHERE t->>'slug' ~ '^[a-z0-9]+(-[a-z0-9]+)*$'
     AND btrim(t->>'name') <> ''
  ON CONFLICT DO NOTHING;

  DELETE FROM public.post_tags pt
   WHERE pt.post_id = p_post_id
     AND pt.tag_id NOT IN (
       SELECT tg.id FROM public.tags tg
        WHERE tg.slug IN (SELECT t->>'slug' FROM jsonb_array_elements(coalesce(p_tags, '[]')) AS t)
     );

  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT p_post_id, tg.id
    FROM public.tags tg
   WHERE tg.slug IN (SELECT t->>'slug' FROM jsonb_array_elements(coalesce(p_tags, '[]')) AS t)
  ON CONFLICT DO NOTHING;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.update_post(uuid, text, text, public.dental_branch, jsonb) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.update_post(uuid, text, text, public.dental_branch, jsonb) TO authenticated;

-- Düzenleme yalnızca RPC ile (doğrulama tek yerde). Sorunun branşı da artık yazılamaz.
REVOKE UPDATE ON public.posts FROM authenticated;
DROP POLICY IF EXISTS "posts_update_own" ON public.posts;
