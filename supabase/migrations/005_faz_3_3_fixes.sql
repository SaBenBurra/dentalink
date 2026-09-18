-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 005: Faz 3.3 Düzeltmeleri
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. increment_view_count RPC Fonksiyonu
CREATE OR REPLACE FUNCTION public.increment_view_count(p_post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
  UPDATE public.posts
  SET view_count = view_count + 1
  WHERE id = p_post_id;
END;
$$;

-- 2. tags Tablosu UPDATE Policy
CREATE POLICY "tags_update_auth" ON public.tags
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

-- 3. likes Tablosu Kısmi Index'lerin UNIQUE Constraint'e Çevrilmesi
-- Daha önce 001'de partial index oluşturmuştuk, PostgREST upsert için gerçek constraint'e ihtiyaç duyar.
DROP INDEX IF EXISTS idx_likes_unique_post;
DROP INDEX IF EXISTS idx_likes_unique_comment;

-- Not: PostgreSQL (versiyona bağlı olarak) partial unique yerine NULLS NOT DISTINCT kullanılarak bu sorun daha kalıcı çözülebilir.
-- Eğer post_id null ise constraint çakışmaz.
ALTER TABLE public.likes ADD CONSTRAINT likes_user_post_key UNIQUE NULLS NOT DISTINCT (user_id, post_id);
ALTER TABLE public.likes ADD CONSTRAINT likes_user_comment_key UNIQUE NULLS NOT DISTINCT (user_id, comment_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ Migration 005 tamamlandı.
-- ═══════════════════════════════════════════════════════════════════════════════
