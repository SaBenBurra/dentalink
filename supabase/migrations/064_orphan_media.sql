-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 064: Sahipsiz medya (ADMIN_PANEL.md madde 12)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Hiçbir kayda bağlı olmayan storage dosyalarını bulur. Silme SQL'den yapılamaz
-- (Supabase storage.objects'ten doğrudan silmeyi engeller): Edge Function
-- media-cleanup her 100'lük grubu silmeden hemen önce bu fonksiyonla yeniden listeler.
-- Bağlı sayılır (yeni bir medya alanı eklenirse media_is_referenced de güncellenir,
-- yoksa kullanılan dosya silinir):
--   post-images  post_images.image_url (bucket içi yol, 015; videonun kapağı da)
--   post-videos  post_images.video_path (046)
--   avatars      users.avatar_url (public URL, sonu bucket içi yol)
-- 24 saatten yeni dosya sayılmaz: yükleme ile create_post / avatar_url yazımı arası.
-- Yetki staff.manage (yeni yetki yok). Mevcut RPC, kolon ve policy değişmez.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.media_is_referenced(p_bucket text, p_name text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT CASE p_bucket
    WHEN 'post-images' THEN EXISTS (SELECT 1 FROM public.post_images i WHERE i.image_url = p_name)
    WHEN 'post-videos' THEN EXISTS (SELECT 1 FROM public.post_images i WHERE i.video_path = p_name)
    WHEN 'avatars' THEN EXISTS (
      SELECT 1 FROM public.users u
       WHERE split_part(u.avatar_url, '/storage/v1/object/public/avatars/', 2) = p_name)
    -- Bilinmeyen bucket: bağlı say, asla silinmesin.
    ELSE true
  END;
$$;

REVOKE EXECUTE ON FUNCTION public.media_is_referenced(text, text) FROM public, anon, authenticated;

-- ─── admin_orphan_media ─────────────────────────────────────────────────────
-- En eski önce. total_count / total_bytes LIMIT'ten önceki bucket toplamı.
CREATE OR REPLACE FUNCTION public.admin_orphan_media(
  p_bucket text,
  p_limit  integer DEFAULT 20
)
RETURNS TABLE (
  name        text,
  size        bigint,
  mimetype    text,
  created_at  timestamptz,
  total_count integer,
  total_bytes bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.has_permission('staff.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_bucket IS NULL OR p_bucket NOT IN ('post-images', 'post-videos', 'avatars') THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT o.name, coalesce((o.metadata->>'size')::bigint, 0), o.metadata->>'mimetype', o.created_at,
         (count(*) OVER ())::integer,
         (sum(coalesce((o.metadata->>'size')::bigint, 0)) OVER ())::bigint
    FROM storage.objects o
   WHERE o.bucket_id = p_bucket
     AND o.created_at < now() - interval '24 hours'
     AND NOT public.media_is_referenced(p_bucket, o.name)
   ORDER BY o.created_at, o.name
   LIMIT least(greatest(coalesce(p_limit, 20), 1), 100);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_orphan_media(text, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_orphan_media(text, integer) TO authenticated;
