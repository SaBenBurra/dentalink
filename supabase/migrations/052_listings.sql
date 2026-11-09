-- ═══════════════════════════════════════════════════════════════════════════════
-- Dentigo — Migration 052: Ticaret (2. el malzeme ilanı)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Uygulama yalnızca ilanı barındırır; pazarlık, ödeme ve teslimat DM'de, iki kişi
-- arasında. İlan: başlık, açıklama, 1–6 görsel (video yok), kategori, durum, şehir,
-- isteğe bağlı fiyat (TL, tam sayı). Etiket yok. Beğeni ve yorum kapalı, kaydetme açık.
-- Satılan ilan (is_sold) ana listeden ve Keşfet'ten düşer, linkle açılınca görünür.
-- posts INSERT/UPDATE istemciye kapalı (015, 016): ilan alanları yalnızca
-- aşağıdaki RPC'lerle yazılır; zorunlu alan kontrolü de orada.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS listing_category text
    CHECK (listing_category IN ('hand_instruments', 'rotary', 'equipment',
                                'consumables', 'books', 'models', 'other')),
  ADD COLUMN IF NOT EXISTS item_condition text
    CHECK (item_condition IN ('new', 'like_new', 'used')),
  ADD COLUMN IF NOT EXISTS price integer
    CHECK (price BETWEEN 0 AND 100000000),
  ADD COLUMN IF NOT EXISTS city text
    CHECK (char_length(city) BETWEEN 1 AND 60),
  ADD COLUMN IF NOT EXISTS is_sold boolean NOT NULL DEFAULT false;

-- Ticaret sekmesi: satılmamış ilanlar, en yeni önce (keyset, keyset.dart).
CREATE INDEX IF NOT EXISTS idx_posts_open_listings
  ON public.posts (created_at DESC, id DESC)
  WHERE type = 'listing' AND NOT is_sold;

-- ─── Ortak doğrulama ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.check_listing_fields(
  p_category  text,
  p_condition text,
  p_city      text
)
RETURNS void
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
BEGIN
  IF p_category IS NULL OR p_condition IS NULL OR nullif(btrim(p_city), '') IS NULL THEN
    RAISE EXCEPTION 'category, condition and city required' USING ERRCODE = '22023';
  END IF;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.check_listing_fields(text, text, text) FROM public, anon, authenticated;

-- ─── create_listing ──────────────────────────────────────────────────────────
-- Görsel yolu, uzunluk ve yetki kontrolleri create_post'ta (046).
CREATE OR REPLACE FUNCTION public.create_listing(
  p_title       text,
  p_content     text,
  p_image_paths text[],
  p_category    text,
  p_condition   text,
  p_city        text,
  p_price       integer DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_post_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  PERFORM public.check_listing_fields(p_category, p_condition, p_city);
  IF cardinality(coalesce(p_image_paths, '{}')) NOT BETWEEN 1 AND 6 THEN
    RAISE EXCEPTION 'listing needs 1-6 images' USING ERRCODE = '22023';
  END IF;

  v_post_id := public.create_post(
    p_type        => 'listing',
    p_title       => p_title,
    p_content     => p_content,
    p_image_paths => p_image_paths
  );
  UPDATE public.posts
     SET listing_category = p_category, item_condition = p_condition,
         city = btrim(p_city), price = p_price
   WHERE id = v_post_id;
  RETURN v_post_id;
END;
$$;

-- ─── update_listing ──────────────────────────────────────────────────────────
-- Sahiplik, metin ve medya sırası kontrolleri update_post'ta (046).
CREATE OR REPLACE FUNCTION public.update_listing(
  p_post_id     uuid,
  p_title       text,
  p_content     text,
  p_category    text,
  p_condition   text,
  p_city        text,
  p_price       integer DEFAULT NULL,
  p_media_order uuid[]  DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM public.check_listing_fields(p_category, p_condition, p_city);
  PERFORM public.update_post(p_post_id, p_title, p_content, '[]'::jsonb, '[]'::jsonb, p_media_order);
  UPDATE public.posts
     SET listing_category = p_category, item_condition = p_condition,
         city = btrim(p_city), price = p_price
   WHERE id = p_post_id AND type = 'listing';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'listing not found' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

-- ─── set_listing_sold ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_listing_sold(p_post_id uuid, p_sold boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.posts SET is_sold = p_sold
   WHERE id = p_post_id AND user_id = auth.uid() AND type = 'listing';
  IF NOT FOUND THEN
    -- Yok, başkasının ya da ilan değil: istemcide "bulunamadı".
    RAISE EXCEPTION 'listing not found' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_listing(text, text, text[], text, text, text, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_listing(text, text, text[], text, text, text, integer) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.update_listing(uuid, text, text, text, text, text, integer, uuid[]) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.update_listing(uuid, text, text, text, text, text, integer, uuid[]) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.set_listing_sold(uuid, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_listing_sold(uuid, boolean) TO authenticated;

-- ─── İlanda beğeni ve yorum yok: konuşma DM'de ───────────────────────────────
CREATE OR REPLACE FUNCTION public.reject_listing_interaction()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.post_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.posts WHERE id = NEW.post_id AND type = 'listing'
  ) THEN
    RAISE EXCEPTION 'listings have no likes or comments' USING ERRCODE = '22023';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.reject_listing_interaction() FROM public, anon, authenticated;

DROP TRIGGER IF EXISTS reject_listing_like ON public.likes;
CREATE TRIGGER reject_listing_like
  BEFORE INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.reject_listing_interaction();

DROP TRIGGER IF EXISTS reject_listing_comment ON public.comments;
CREATE TRIGGER reject_listing_comment
  BEFORE INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.reject_listing_interaction();

-- ─── Keşfet: ilan yalnızca metin aramasında ve satılmamışsa ──────────────────
-- 040'taki gövde, tek ek koşulla.
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
     AND (p.type <> 'listing' OR (q.tsq IS NOT NULL AND NOT p.is_sold))
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

-- ─── Rapor sebebi: yasaklı ürün ya da dolandırıcılık ─────────────────────────
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_reason_check;
ALTER TABLE public.reports ADD CONSTRAINT reports_reason_check
  CHECK (reason IN ('spam', 'harassment', 'patient_privacy', 'misinformation',
                    'inappropriate', 'prohibited_item', 'other'));
