-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 026: yorumlara yanıt (sınırsız derinlik)
-- ═══════════════════════════════════════════════════════════════════════════════
-- - comments.parent_id: yanıtlanan yorum; NULL = üst seviye yorum/cevap.
--   Ebeveyn silinirse alt ağaç da silinir (posts.comment_count trigger'ı her
--   satır için çalıştığından sayaç doğru düşer).
-- - comments.reply_count: doğrudan yanıt sayısı, yalnızca trigger yazar.
-- - Yanıt aynı posta ait olmalı; engelli çift birbirine yanıt veremez.
-- - En iyi cevap yalnızca üst seviye yorum olabilir.
-- - Bildirim: üst seviye yorum → post sahibi ('comment'),
--   yanıt → yanıtlanan yorumun sahibi ('reply').
-- - reconcile_counters() reply_count'u da uzlaştırır.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'reply';

ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS parent_id uuid REFERENCES public.comments(id) ON DELETE CASCADE;
ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS reply_count integer NOT NULL DEFAULT 0;
ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_reply_count_nonneg;
ALTER TABLE public.comments ADD CONSTRAINT comments_reply_count_nonneg CHECK (reply_count >= 0);

-- Yanıt sayfası: (parent_id, created_at, id) keyset.
CREATE INDEX IF NOT EXISTS idx_comments_parent
  ON public.comments (parent_id, created_at, id) WHERE parent_id IS NOT NULL;

GRANT INSERT (parent_id) ON public.comments TO authenticated;


-- ─── 1. Yanıt doğrulaması ────────────────────────────────────────────────────
-- SECURITY DEFINER: engelli çiftte ebeveyn RLS ile gizli olsa da okunabilsin.
CREATE OR REPLACE FUNCTION public.validate_comment_parent()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_post_id uuid;
  v_user_id uuid;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT post_id, user_id INTO v_post_id, v_user_id
    FROM public.comments WHERE id = NEW.parent_id;
  -- Ebeveyn yoksa FK 23503 ile reddeder.
  IF NOT FOUND THEN
    RETURN NEW;
  END IF;
  IF v_post_id <> NEW.post_id THEN
    RAISE EXCEPTION 'parent comment belongs to another post' USING ERRCODE = '22023';
  END IF;
  IF public.is_blocked_between(NEW.user_id, v_user_id) THEN
    RAISE EXCEPTION 'blocked' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.validate_comment_parent() FROM public, anon, authenticated;

DROP TRIGGER IF EXISTS trg_validate_comment_parent ON public.comments;
CREATE TRIGGER trg_validate_comment_parent
  BEFORE INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.validate_comment_parent();


-- ─── 2. reply_count ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_comment_reply_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.parent_id IS NOT NULL THEN
      UPDATE public.comments SET reply_count = reply_count + 1 WHERE id = NEW.parent_id;
    END IF;
    RETURN NEW;
  END IF;
  -- Ebeveyn de silinmekteyse (cascade) UPDATE 0 satır etkiler.
  IF OLD.parent_id IS NOT NULL THEN
    UPDATE public.comments SET reply_count = GREATEST(reply_count - 1, 0) WHERE id = OLD.parent_id;
  END IF;
  RETURN OLD;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.update_comment_reply_count() FROM public, anon, authenticated;

DROP TRIGGER IF EXISTS trg_comment_reply_count ON public.comments;
CREATE TRIGGER trg_comment_reply_count
  AFTER INSERT OR DELETE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.update_comment_reply_count();


-- ─── 3. Bildirim: yanıt → yanıtlanan yorumun sahibi ──────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_comment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_owner uuid;
BEGIN
  IF NEW.parent_id IS NULL THEN
    SELECT user_id INTO v_owner FROM public.posts WHERE id = NEW.post_id;
    PERFORM public.create_notification(v_owner, NEW.user_id, 'comment', NEW.post_id, NEW.id);
  ELSE
    SELECT user_id INTO v_owner FROM public.comments WHERE id = NEW.parent_id;
    PERFORM public.create_notification(v_owner, NEW.user_id, 'reply', NEW.post_id, NEW.id);
  END IF;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.notify_on_comment() FROM public, anon, authenticated;


-- ─── 4. En iyi cevap yalnızca üst seviye yorum ───────────────────────────────
CREATE OR REPLACE FUNCTION public.mark_best_answer(p_comment_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_post_id   uuid;
  v_parent_id uuid;
  v_type      public.post_type;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT post_id, parent_id INTO v_post_id, v_parent_id
    FROM public.comments WHERE id = p_comment_id;
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
  IF v_parent_id IS NOT NULL THEN
    RAISE EXCEPTION 'best answer only for top-level comments' USING ERRCODE = '22023';
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


-- ─── 5. reconcile_counters: reply_count eklendi (021'in kopyası + 1 blok) ────
CREATE OR REPLACE FUNCTION public.reconcile_counters()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb := '{}'::jsonb;
  v_n      bigint;
BEGIN
  -- shortcut: tablo kilitlemeden sayar; sayım ile güncelleme arasına giren
  -- bir beğeni bir sonraki çalıştırmaya kadar ±1 kalabilir. Sorun olursa
  -- satır kilidi (FOR UPDATE) ekle.

  UPDATE public.posts p SET like_count = s.n
    FROM (SELECT p2.id, count(l.id) AS n
            FROM public.posts p2
            LEFT JOIN public.likes l ON l.post_id = p2.id
           GROUP BY p2.id) s
   WHERE s.id = p.id AND p.like_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.like_count', v_n);

  UPDATE public.posts p SET comment_count = s.n
    FROM (SELECT p2.id, count(c.id) AS n
            FROM public.posts p2
            LEFT JOIN public.comments c ON c.post_id = p2.id
           GROUP BY p2.id) s
   WHERE s.id = p.id AND p.comment_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.comment_count', v_n);

  UPDATE public.posts p SET bookmark_count = s.n
    FROM (SELECT p2.id, count(b.id) AS n
            FROM public.posts p2
            LEFT JOIN public.bookmarks b ON b.post_id = p2.id
           GROUP BY p2.id) s
   WHERE s.id = p.id AND p.bookmark_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.bookmark_count', v_n);

  -- view_count'un kaynak tablosu yok; yalnızca negatif değer sıfırlanır.
  UPDATE public.posts SET view_count = 0 WHERE view_count < 0;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('posts.view_count', v_n);

  UPDATE public.comments c SET like_count = s.n
    FROM (SELECT c2.id, count(l.id) AS n
            FROM public.comments c2
            LEFT JOIN public.likes l ON l.comment_id = c2.id
           GROUP BY c2.id) s
   WHERE s.id = c.id AND c.like_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('comments.like_count', v_n);

  UPDATE public.comments c SET reply_count = s.n
    FROM (SELECT c2.id, count(r.id) AS n
            FROM public.comments c2
            LEFT JOIN public.comments r ON r.parent_id = c2.id
           GROUP BY c2.id) s
   WHERE s.id = c.id AND c.reply_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('comments.reply_count', v_n);

  UPDATE public.users u SET followers_count = s.n
    FROM (SELECT u2.id, count(f.follower_id) AS n
            FROM public.users u2
            LEFT JOIN public.follows f ON f.following_id = u2.id
           GROUP BY u2.id) s
   WHERE s.id = u.id AND u.followers_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('users.followers_count', v_n);

  UPDATE public.users u SET following_count = s.n
    FROM (SELECT u2.id, count(f.following_id) AS n
            FROM public.users u2
            LEFT JOIN public.follows f ON f.follower_id = u2.id
           GROUP BY u2.id) s
   WHERE s.id = u.id AND u.following_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('users.following_count', v_n);

  UPDATE public.users u SET posts_count = s.n
    FROM (SELECT u2.id, count(p.id) AS n
            FROM public.users u2
            LEFT JOIN public.posts p ON p.user_id = u2.id
           GROUP BY u2.id) s
   WHERE s.id = u.id AND u.posts_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('users.posts_count', v_n);

  UPDATE public.tags t SET usage_count = s.n
    FROM (SELECT t2.id, count(pt.post_id) AS n
            FROM public.tags t2
            LEFT JOIN public.post_tags pt ON pt.tag_id = t2.id
           GROUP BY t2.id) s
   WHERE s.id = t.id AND t.usage_count IS DISTINCT FROM s.n;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('tags.usage_count', v_n);

  -- Okunmamış = alıcının is_read = false mesajları (trigger ve
  -- mark_messages_as_read ile aynı anlam; soft delete ayrıca sayılmaz).
  UPDATE public.conversations c
     SET user1_unread_count = s.n1, user2_unread_count = s.n2
    FROM (SELECT c2.id,
                 count(m.id) FILTER (WHERE m.receiver_id = c2.user1_id) AS n1,
                 count(m.id) FILTER (WHERE m.receiver_id = c2.user2_id) AS n2
            FROM public.conversations c2
            LEFT JOIN public.messages m
              ON m.conversation_id = c2.id AND m.is_read = false
           GROUP BY c2.id) s
   WHERE s.id = c.id
     AND (c.user1_unread_count IS DISTINCT FROM s.n1
       OR c.user2_unread_count IS DISTINCT FROM s.n2);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  v_result := v_result || jsonb_build_object('conversations.unread_count', v_n);

  RETURN v_result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.reconcile_counters() FROM public, anon, authenticated;
