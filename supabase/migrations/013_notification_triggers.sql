-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 013: Bildirim trigger'ları (DATA-5)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Beğeni, yorum, takip ve en iyi cevap → alıcıya `notifications` satırı.
-- İstemci notifications'a yazamaz (012); yalnızca bu SECURITY DEFINER
-- fonksiyonlar yazar. Aktör = alıcı ise bildirim oluşmaz.
-- Mesajlar için bildirim yazılmaz: sohbet listesindeki unread_count yeterli.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── 1. Ortak yardımcı ───────────────────────────────────────────────────────
-- Beğen/geri al/beğen spam'i aynı okunmamış bildirimi çoğaltmasın.
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id    uuid,
  p_actor_id   uuid,
  p_type       public.notification_type,
  p_post_id    uuid,
  p_comment_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF p_user_id IS NULL OR p_user_id = p_actor_id THEN
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.notifications
     WHERE user_id = p_user_id
       AND actor_id = p_actor_id
       AND type = p_type
       AND post_id IS NOT DISTINCT FROM p_post_id
       AND comment_id IS NOT DISTINCT FROM p_comment_id
       AND is_read = false
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id)
  VALUES (p_user_id, p_actor_id, p_type, p_post_id, p_comment_id);
END;
$$;

-- Yalnızca trigger'lar çağırır; istemci RPC olarak çağıramasın.
REVOKE EXECUTE ON FUNCTION public.create_notification(uuid, uuid, public.notification_type, uuid, uuid)
  FROM public, anon, authenticated;


-- ─── 2. Beğeni (post veya yorum) ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_like()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_owner   uuid;
  v_post_id uuid;
BEGIN
  IF NEW.post_id IS NOT NULL THEN
    SELECT user_id INTO v_owner FROM public.posts WHERE id = NEW.post_id;
    v_post_id := NEW.post_id;
  ELSE
    SELECT user_id, post_id INTO v_owner, v_post_id
      FROM public.comments WHERE id = NEW.comment_id;
  END IF;

  PERFORM public.create_notification(v_owner, NEW.user_id, 'like', v_post_id, NEW.comment_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_like ON public.likes;
CREATE TRIGGER trg_notify_on_like
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_like();


-- ─── 3. Yorum / cevap → post sahibi ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_comment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_owner uuid;
BEGIN
  SELECT user_id INTO v_owner FROM public.posts WHERE id = NEW.post_id;
  PERFORM public.create_notification(v_owner, NEW.user_id, 'comment', NEW.post_id, NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_comment ON public.comments;
CREATE TRIGGER trg_notify_on_comment
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_comment();


-- ─── 4. Takip ────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM public.create_notification(NEW.following_id, NEW.follower_id, 'follow', NULL, NULL);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_follow ON public.follows;
CREATE TRIGGER trg_notify_on_follow
  AFTER INSERT ON public.follows
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_follow();


-- ─── 5. En iyi cevap → yorum sahibi (aktör = soru sahibi) ────────────────────
-- mark_best_answer RPC'sine dokunmadan, is_best_answer false→true geçişini yakalar.
CREATE OR REPLACE FUNCTION public.notify_on_best_answer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_post_owner uuid;
BEGIN
  SELECT user_id INTO v_post_owner FROM public.posts WHERE id = NEW.post_id;
  PERFORM public.create_notification(NEW.user_id, v_post_owner, 'best_answer', NEW.post_id, NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_best_answer ON public.comments;
CREATE TRIGGER trg_notify_on_best_answer
  AFTER UPDATE OF is_best_answer ON public.comments
  FOR EACH ROW
  WHEN (NEW.is_best_answer AND NOT OLD.is_best_answer)
  EXECUTE FUNCTION public.notify_on_best_answer();


-- Trigger fonksiyonları doğrudan çağrılamasın.
REVOKE EXECUTE ON FUNCTION public.notify_on_like()        FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_on_comment()     FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_on_follow()      FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_on_best_answer() FROM public, anon, authenticated;


-- ─── 6. Realtime yayını ──────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;
