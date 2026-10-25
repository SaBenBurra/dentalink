-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 023: Raporlama ve engelleme (UX-6)
-- ═══════════════════════════════════════════════════════════════════════════════
-- reports: istemci yalnızca ekler, okuyamaz. Kuyruk Dashboard'dan yönetilir
--          (docs/SUPABASE.md §6).
-- blocks:  iki yönlü gizler. Engelleyen ve engellenen birbirinin post ve
--          yorumunu görmez, birbirine mesaj atamaz ve takip edemez. Mevcut
--          takipler silinir. Eski mesaj geçmişi görünür kalır.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── reports ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reports (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id  uuid        NOT NULL DEFAULT auth.uid()
                           REFERENCES public.users(id) ON DELETE CASCADE,
  target_type  text        NOT NULL
                           CHECK (target_type IN ('post', 'comment', 'user')),
  target_id    uuid        NOT NULL,
  reason       text        NOT NULL
                           CHECK (reason IN ('spam', 'harassment', 'patient_privacy',
                                             'misinformation', 'inappropriate', 'other')),
  note         text        CHECK (char_length(note) <= 500),
  status       text        NOT NULL DEFAULT 'open'
                           CHECK (status IN ('open', 'actioned', 'dismissed')),
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (reporter_id, target_type, target_id)
);

CREATE INDEX IF NOT EXISTS reports_open_idx
  ON public.reports (created_at) WHERE status = 'open';

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reports_insert_own" ON public.reports;
CREATE POLICY "reports_insert_own" ON public.reports
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = reporter_id);

REVOKE ALL ON public.reports FROM anon, authenticated;
GRANT INSERT (reporter_id, target_type, target_id, reason, note)
  ON public.reports TO authenticated;

-- ─── blocks ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.blocks (
  blocker_id  uuid        NOT NULL DEFAULT auth.uid()
                          REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_id  uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS blocks_blocked_idx ON public.blocks (blocked_id);

ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "blocks_select_own" ON public.blocks;
CREATE POLICY "blocks_select_own" ON public.blocks
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = blocker_id);

DROP POLICY IF EXISTS "blocks_insert_own" ON public.blocks;
CREATE POLICY "blocks_insert_own" ON public.blocks
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = blocker_id);

DROP POLICY IF EXISTS "blocks_delete_own" ON public.blocks;
CREATE POLICY "blocks_delete_own" ON public.blocks
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = blocker_id);

REVOKE ALL ON public.blocks FROM anon, authenticated;
GRANT SELECT, DELETE ON public.blocks TO authenticated;
GRANT INSERT (blocker_id, blocked_id) ON public.blocks TO authenticated;

-- İki yönlü kontrol. Definer: "beni kim engelledi" satırlarını istemciye
-- açmadan RLS içinde okuyabilmek için.
CREATE OR REPLACE FUNCTION public.is_blocked_between(p_a uuid, p_b uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.blocks
     WHERE (blocker_id = p_a AND blocked_id = p_b)
        OR (blocker_id = p_b AND blocked_id = p_a)
  );
$$;

REVOKE EXECUTE ON FUNCTION public.is_blocked_between(uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.is_blocked_between(uuid, uuid) TO authenticated;

-- Engelleyince iki yöndeki takip silinir (sayaç trigger'ları düzeltir).
CREATE OR REPLACE FUNCTION public.drop_follows_on_block()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.follows
   WHERE (follower_id = NEW.blocker_id AND following_id = NEW.blocked_id)
      OR (follower_id = NEW.blocked_id AND following_id = NEW.blocker_id);
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.drop_follows_on_block() FROM public, anon, authenticated;

DROP TRIGGER IF EXISTS on_block_drop_follows ON public.blocks;
CREATE TRIGGER on_block_drop_follows
  AFTER INSERT ON public.blocks
  FOR EACH ROW EXECUTE FUNCTION public.drop_follows_on_block();

-- ─── Görünürlük ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "posts_select_all" ON public.posts;
CREATE POLICY "posts_select_all" ON public.posts
  FOR SELECT TO authenticated
  USING (NOT public.is_blocked_between((select auth.uid()), user_id));

DROP POLICY IF EXISTS "comments_select_all" ON public.comments;
CREATE POLICY "comments_select_all" ON public.comments
  FOR SELECT TO authenticated
  USING (NOT public.is_blocked_between((select auth.uid()), user_id));

DROP POLICY IF EXISTS "follows_insert_own" ON public.follows;
CREATE POLICY "follows_insert_own" ON public.follows
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = follower_id
    AND NOT public.is_blocked_between(follower_id, following_id)
  );

-- ─── send_message: engel varsa reddet ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.send_message(p_receiver_id uuid, p_content text)
RETURNS public.messages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_content text := btrim(p_content);
  v_user1   uuid;
  v_user2   uuid;
  v_conv_id uuid;
  v_msg     public.messages;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF p_receiver_id IS NULL OR p_receiver_id = v_uid THEN
    RAISE EXCEPTION 'invalid receiver' USING ERRCODE = '22023';
  END IF;
  IF v_content IS NULL OR v_content = '' OR char_length(v_content) > 2000 THEN
    RAISE EXCEPTION 'invalid content' USING ERRCODE = '22023';
  END IF;
  IF public.is_blocked_between(v_uid, p_receiver_id) THEN
    RAISE EXCEPTION 'blocked' USING ERRCODE = '42501';
  END IF;

  v_user1 := LEAST(v_uid, p_receiver_id);
  v_user2 := GREATEST(v_uid, p_receiver_id);

  INSERT INTO public.conversations (user1_id, user2_id)
  VALUES (v_user1, v_user2)
  ON CONFLICT (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id)) DO NOTHING
  RETURNING id INTO v_conv_id;

  IF v_conv_id IS NULL THEN
    -- 012 öncesi sırasız eklenmiş çiftler de bulunsun.
    SELECT id INTO v_conv_id
      FROM public.conversations
     WHERE LEAST(user1_id, user2_id) = v_user1
       AND GREATEST(user1_id, user2_id) = v_user2;
  END IF;

  INSERT INTO public.messages (conversation_id, sender_id, receiver_id, content)
  VALUES (v_conv_id, v_uid, p_receiver_id, v_content)
  RETURNING * INTO v_msg;

  RETURN v_msg;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.send_message(uuid, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.send_message(uuid, text) TO authenticated;
