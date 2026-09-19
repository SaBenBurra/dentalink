-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 008: Security Definer ve Race Condition Yaması
-- ═══════════════════════════════════════════════════════════════════════════════
-- Önkoşul: 002 ve 007 çalıştırılmış olmalı.
-- Amaç: Sayaç güncelleyen tüm trigger fonksiyonlarının RLS engelini aşabilmesi
-- için SECURITY DEFINER yapılması. mark_best_answer içine FOR UPDATE kilidi eklenmesi.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. MARK BEST ANSWER (Eşzamanlılık Kilidi + Security Definer)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.mark_best_answer(p_comment_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER 
SET search_path = public
AS $$
DECLARE
  v_post_id uuid;
BEGIN
  SELECT post_id INTO v_post_id FROM comments WHERE id = p_comment_id;

  IF v_post_id IS NULL THEN
    RAISE EXCEPTION 'Yorum bulunamadı' USING ERRCODE = 'P0002'; -- no_data_found
  END IF;

  -- Satırı kilitle: Eşzamanlı çağrıları sıraya sokar ve sadece post sahibinin yapabilmesini garanti eder
  PERFORM 1 FROM posts
   WHERE id = v_post_id AND user_id = auth.uid() FOR UPDATE;
   
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bu işlem için yetkiniz yok' USING ERRCODE = '42501'; -- insufficient_privilege
  END IF;

  UPDATE comments SET is_best_answer = false
   WHERE post_id = v_post_id AND is_best_answer = true;
   
  UPDATE comments SET is_best_answer = true WHERE id = p_comment_id;
  
  UPDATE posts SET is_solved = true WHERE id = v_post_id;
END;
$$;

-- Açıkça yetki sınırlandırması (güvenlik iyi uygulaması)
REVOKE EXECUTE ON FUNCTION public.mark_best_answer(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mark_best_answer(uuid) TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. SAYAC GÜNCELLEYİCİ TRIGGER FONKSİYONLARININ SECURITY DEFINER YAPILMASI
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_post_like_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.post_id IS NOT NULL THEN
    UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' AND OLD.post_id IS NOT NULL THEN
    UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_comment_like_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.comment_id IS NOT NULL THEN
    UPDATE comments SET like_count = like_count + 1 WHERE id = NEW.comment_id;
  ELSIF TG_OP = 'DELETE' AND OLD.comment_id IS NOT NULL THEN
    UPDATE comments SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.comment_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_post_comment_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_post_bookmark_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET bookmark_count = bookmark_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET bookmark_count = GREATEST(bookmark_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_follow_counts()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    UPDATE users SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
    UPDATE users SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.following_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user_posts_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE users SET posts_count = GREATEST(posts_count - 1, 0) WHERE id = OLD.user_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_tag_usage_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tags SET usage_count = GREATEST(usage_count - 1, 0) WHERE id = OLD.tag_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_conversation_on_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user1_id uuid;
  v_user2_id uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT user1_id, user2_id INTO v_user1_id, v_user2_id
    FROM conversations WHERE id = NEW.conversation_id;

    IF NEW.receiver_id = v_user1_id THEN
      UPDATE conversations SET
        last_message_at = NEW.created_at,
        last_message_preview = LEFT(NEW.content, 100),
        user1_unread_count = user1_unread_count + 1
      WHERE id = NEW.conversation_id;
    ELSE
      UPDATE conversations SET
        last_message_at = NEW.created_at,
        last_message_preview = LEFT(NEW.content, 100),
        user2_unread_count = user2_unread_count + 1
      WHERE id = NEW.conversation_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
