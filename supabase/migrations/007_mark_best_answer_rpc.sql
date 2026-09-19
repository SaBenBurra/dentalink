-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 007: Mark Best Answer RPC ve Data Integrity
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Her sorunun (post_id) yalnızca bir tane 'en iyi cevabı' olabileceğini garanti ederiz.
CREATE UNIQUE INDEX IF NOT EXISTS one_best_answer_per_post
  ON public.comments(post_id) WHERE is_best_answer = true;

-- 2. "En İyi Cevap" işaretleme RPC'si
-- RLS politikaları sadece kendi yorumunu güncellemeye izin verdiği için,
-- post sahibi başkasının yorumunu güncelleyemezdi. SECURITY DEFINER ile
-- RLS bypass edilip yetki kontrolü fonksiyon içinde yapılır.
CREATE OR REPLACE FUNCTION public.mark_best_answer(p_comment_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_post_id uuid;
BEGIN
  -- Yorumun ait olduğu post_id'yi bul
  SELECT post_id INTO v_post_id FROM public.comments WHERE id = p_comment_id;

  IF v_post_id IS NULL THEN
    RAISE EXCEPTION 'Yorum bulunamadı' USING ERRCODE = 'P0002'; -- no_data_found
  END IF;

  -- İşlemi yapan kişi postun sahibi mi kontrol et
  IF NOT EXISTS (
    SELECT 1 FROM public.posts
    WHERE id = v_post_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Bu işlem için yetkiniz yok' USING ERRCODE = '42501'; -- insufficient_privilege
  END IF;

  -- Önceki en iyi cevabı false yap
  UPDATE public.comments
  SET is_best_answer = false
  WHERE post_id = v_post_id AND is_best_answer = true;

  -- Seçilen yorumu en iyi cevap yap
  UPDATE public.comments
  SET is_best_answer = true
  WHERE id = p_comment_id;

  -- Soruyu çözüldü olarak işaretle
  UPDATE public.posts
  SET is_solved = true
  WHERE id = v_post_id;
END;
$$;
