-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 017: en iyi cevap düzeltmeleri (DATA-16), uzunluk
-- kontrolleri (DATA-17)
-- ═══════════════════════════════════════════════════════════════════════════════
-- - mark_best_answer yalnızca soru postunda çalışır.
-- - unmark_best_answer: soru sahibi seçimi geri alır, soru çözülmemiş olur.
-- - En iyi cevap silinirse soru çözülmemiş olur.
-- - İçerik ve etiket uzunlukları DB'de sınırlı (istemcideki maxLength ile aynı):
--   post başlığı 150, post içeriği 5000, yorum ve mesaj 2000, etiket 30 karakter,
--   post başına en fazla 5 etiket. İhlal 23514 → istemcide ValidationFailure.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. mark_best_answer: tip kontrolü
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.mark_best_answer(p_comment_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_post_id uuid;
  v_type    public.post_type;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT post_id INTO v_post_id FROM public.comments WHERE id = p_comment_id;
  IF v_post_id IS NULL THEN
    RAISE EXCEPTION 'comment not found' USING ERRCODE = 'P0002';
  END IF;

  -- Kilit eşzamanlı seçimleri sıraya sokar; yalnızca post sahibi geçer.
  SELECT type INTO v_type FROM public.posts
   WHERE id = v_post_id AND user_id = auth.uid()
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not post owner' USING ERRCODE = '42501';
  END IF;
  IF v_type <> 'question' THEN
    RAISE EXCEPTION 'best answer only for questions' USING ERRCODE = '22023';
  END IF;

  UPDATE public.comments SET is_best_answer = false
   WHERE post_id = v_post_id AND is_best_answer AND id <> p_comment_id;
  UPDATE public.comments SET is_best_answer = true
   WHERE id = p_comment_id AND NOT is_best_answer;
  UPDATE public.posts SET is_solved = true WHERE id = v_post_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.mark_best_answer(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mark_best_answer(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. unmark_best_answer
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.unmark_best_answer(p_comment_id uuid)
RETURNS void
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

  SELECT post_id INTO v_post_id FROM public.comments WHERE id = p_comment_id;
  IF v_post_id IS NULL THEN
    RAISE EXCEPTION 'comment not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM 1 FROM public.posts
   WHERE id = v_post_id AND user_id = auth.uid()
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not post owner' USING ERRCODE = '42501';
  END IF;

  -- Zaten seçili değilse sessizce geçer (çift dokunuş).
  UPDATE public.comments SET is_best_answer = false
   WHERE id = p_comment_id AND is_best_answer;
  UPDATE public.posts p SET is_solved = false
   WHERE p.id = v_post_id
     AND NOT EXISTS (
       SELECT 1 FROM public.comments c WHERE c.post_id = v_post_id AND c.is_best_answer
     );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.unmark_best_answer(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.unmark_best_answer(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. En iyi cevap silinince soru çözülmemiş olur
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.unsolve_on_best_answer_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.posts SET is_solved = false WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.unsolve_on_best_answer_delete() FROM public, anon, authenticated;

DROP TRIGGER IF EXISTS trg_unsolve_on_best_answer_delete ON public.comments;
CREATE TRIGGER trg_unsolve_on_best_answer_delete
  AFTER DELETE ON public.comments
  FOR EACH ROW
  WHEN (OLD.is_best_answer)
  EXECUTE FUNCTION public.unsolve_on_best_answer_delete();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Uzunluk CHECK'leri (mevcut satır ihlal ederse migration bütünüyle geri alınır)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_title_length;
ALTER TABLE public.posts ADD CONSTRAINT posts_title_length
  CHECK (char_length(btrim(title)) BETWEEN 1 AND 150);

ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_content_length;
ALTER TABLE public.posts ADD CONSTRAINT posts_content_length
  CHECK (char_length(btrim(content)) BETWEEN 1 AND 5000);

ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_content_length;
ALTER TABLE public.comments ADD CONSTRAINT comments_content_length
  CHECK (char_length(btrim(content)) BETWEEN 1 AND 2000);

ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_content_length;
ALTER TABLE public.messages ADD CONSTRAINT messages_content_length
  CHECK (char_length(btrim(content)) BETWEEN 1 AND 2000);

ALTER TABLE public.tags DROP CONSTRAINT IF EXISTS tags_name_length;
ALTER TABLE public.tags ADD CONSTRAINT tags_name_length
  CHECK (char_length(name) BETWEEN 1 AND 30);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Post başına en fazla 5 etiket
-- ─────────────────────────────────────────────────────────────────────────────
-- Yalnızca yeni bağda sayılır: 5'ten fazla eski etiketi olan post düzenlenebilir.
CREATE OR REPLACE FUNCTION public.limit_post_tags()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF (SELECT count(*) FROM public.post_tags WHERE post_id = NEW.post_id) >= 5 THEN
    RAISE EXCEPTION 'too many tags' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.limit_post_tags() FROM public, anon, authenticated;

DROP TRIGGER IF EXISTS trg_limit_post_tags ON public.post_tags;
CREATE TRIGGER trg_limit_post_tags
  BEFORE INSERT ON public.post_tags
  FOR EACH ROW
  EXECUTE FUNCTION public.limit_post_tags();
