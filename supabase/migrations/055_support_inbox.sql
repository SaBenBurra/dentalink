-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 055: Panel destek kutusu
-- ═══════════════════════════════════════════════════════════════════════════════
-- waiting_since:         sohbetin cevap beklemeye başladığı an (ilk cevapsız kullanıcı
--                        mesajı). Kuyruk sırası ve 24 saat işareti bununla; kullanıcı
--                        üst üste yazınca sırası geriye düşmez. Cevap, iç not olmayan
--                        reply_support ya da open dışı durum NULL yapar.
-- assign_support_thread: sohbeti bir personele atar (NULL: atamayı kaldırır). Atanan
--                        support.reply yetkili olmalı; staff_actions'a yazar.
-- 049 policy'leri ve mark_support_read has_permission('support.reply')'a taşınır
-- (davranış aynı: has_staff_role('support') zaten bu yetkiye bakıyordu, 053).
-- send_support_message imzası ve davranışı aynı, yalnızca waiting_since'i tutar.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── waiting_since ──────────────────────────────────────────────────────────
ALTER TABLE public.support_threads ADD COLUMN IF NOT EXISTS waiting_since timestamptz;

-- Mevcut açık sohbetler: son herkese açık personel cevabından sonraki ilk kullanıcı mesajı.
UPDATE public.support_threads t
   SET waiting_since = coalesce((
         SELECT min(m.created_at) FROM public.support_messages m
          WHERE m.thread_id = t.id AND NOT m.from_staff
            AND m.created_at > coalesce((
                  SELECT max(s.created_at) FROM public.support_messages s
                   WHERE s.thread_id = t.id AND s.from_staff AND NOT s.internal),
                  '-infinity')),
         t.last_message_at)
 WHERE t.status = 'open' AND t.waiting_since IS NULL;

CREATE INDEX IF NOT EXISTS support_threads_waiting_idx
  ON public.support_threads (status, waiting_since);

-- ─── Policy'ler: has_permission ─────────────────────────────────────────────
DROP POLICY IF EXISTS "support_threads_select" ON public.support_threads;
CREATE POLICY "support_threads_select" ON public.support_threads
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()) OR (select public.has_permission('support.reply')));

DROP POLICY IF EXISTS "support_messages_select" ON public.support_messages;
CREATE POLICY "support_messages_select" ON public.support_messages
  FOR SELECT TO authenticated
  USING (
    (select public.has_permission('support.reply'))
    OR (NOT internal AND EXISTS (
      SELECT 1 FROM public.support_threads t
       WHERE t.id = thread_id AND t.user_id = (select auth.uid())
    ))
  );

-- ─── RPC: kullanıcı yazar (049 + waiting_since) ─────────────────────────────
CREATE OR REPLACE FUNCTION public.send_support_message(
  p_content     text,
  p_category    text DEFAULT NULL,
  p_client_info text DEFAULT NULL
)
RETURNS public.support_messages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_content text := btrim(p_content);
  v_thread  uuid;
  v_msg     public.support_messages;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF v_content IS NULL OR v_content = '' OR char_length(v_content) > 2000 THEN
    RAISE EXCEPTION 'invalid content' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.support_threads AS t
         (user_id, category, client_info, user_read_at, waiting_since)
  VALUES (v_uid, p_category, left(p_client_info, 200), now(), now())
  ON CONFLICT (user_id) DO UPDATE
     SET status          = 'open',
         category        = coalesce(EXCLUDED.category, t.category),
         client_info     = coalesce(EXCLUDED.client_info, t.client_info),
         last_message_at = now(),
         user_read_at    = now(),
         waiting_since   = coalesce(t.waiting_since, now())
  RETURNING id INTO v_thread;

  -- Taşkın sınırı: 10 dakikada 20 mesaj.
  IF (SELECT count(*) FROM public.support_messages
       WHERE thread_id = v_thread AND NOT from_staff
         AND created_at > now() - interval '10 minutes') >= 20 THEN
    RAISE EXCEPTION 'rate limited' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.support_messages (thread_id, sender_id, from_staff, content)
  VALUES (v_thread, v_uid, false, v_content)
  RETURNING * INTO v_msg;

  RETURN v_msg;
END;
$$;

-- ─── RPC: personel cevaplar (053 + waiting_since) ───────────────────────────
CREATE OR REPLACE FUNCTION public.reply_support(
  p_thread_id uuid,
  p_content   text,
  p_internal  boolean DEFAULT false
)
RETURNS public.support_messages
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_content text := btrim(p_content);
  v_msg     public.support_messages;
BEGIN
  IF NOT public.has_permission('support.reply') THEN
    RAISE EXCEPTION 'not staff' USING ERRCODE = '42501';
  END IF;
  IF v_content IS NULL OR v_content = '' OR char_length(v_content) > 2000 THEN
    RAISE EXCEPTION 'invalid content' USING ERRCODE = '22023';
  END IF;

  IF p_internal THEN
    -- İç not durumu ve kullanıcının gördüğü zamanı değiştirmez.
    UPDATE public.support_threads
       SET staff_read_at = now()
     WHERE id = p_thread_id;
  ELSE
    UPDATE public.support_threads
       SET status            = 'answered',
           assignee_id       = coalesce(assignee_id, v_uid),
           first_response_at = coalesce(first_response_at, now()),
           last_message_at   = now(),
           staff_read_at     = now(),
           waiting_since     = NULL
     WHERE id = p_thread_id;
  END IF;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'thread not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.support_messages (thread_id, sender_id, from_staff, content, internal)
  VALUES (p_thread_id, v_uid, true, v_content, coalesce(p_internal, false))
  RETURNING * INTO v_msg;

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('support.reply', 'support_thread', p_thread_id::text,
          jsonb_build_object('message', v_msg.id, 'internal', v_msg.internal));

  RETURN v_msg;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_support_status(
  p_thread_id uuid,
  p_status    text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.has_permission('support.reply') THEN
    RAISE EXCEPTION 'not staff' USING ERRCODE = '42501';
  END IF;
  IF p_status IS NULL OR p_status NOT IN ('open', 'answered', 'resolved') THEN
    RAISE EXCEPTION 'invalid status' USING ERRCODE = '22023';
  END IF;

  IF p_status = 'open' THEN
    UPDATE public.support_threads
       SET status = p_status, waiting_since = coalesce(waiting_since, now())
     WHERE id = p_thread_id;
  ELSE
    UPDATE public.support_threads
       SET status = p_status, waiting_since = NULL
     WHERE id = p_thread_id;
  END IF;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'thread not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('support.status', 'support_thread', p_thread_id::text,
          jsonb_build_object('status', p_status));
END;
$$;

-- ─── RPC: okundu (049, has_permission) ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.mark_support_read(p_thread_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  UPDATE public.support_threads
     SET user_read_at = now()
   WHERE id = p_thread_id AND user_id = v_uid;
  IF FOUND THEN
    RETURN;
  END IF;

  IF public.has_permission('support.reply') THEN
    UPDATE public.support_threads SET staff_read_at = now() WHERE id = p_thread_id;
  END IF;
END;
$$;

-- ─── RPC: atama ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.assign_support_thread(
  p_thread_id   uuid,
  p_assignee_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old uuid;
BEGIN
  IF NOT public.has_permission('support.reply') THEN
    RAISE EXCEPTION 'not staff' USING ERRCODE = '42501';
  END IF;
  IF p_assignee_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.staff s
      JOIN public.staff_roles r ON r.name = s.role
     WHERE s.user_id = p_assignee_id AND 'support.reply' = ANY (r.permissions)
  ) THEN
    RAISE EXCEPTION 'assignee not support' USING ERRCODE = '22023';
  END IF;

  SELECT assignee_id INTO v_old FROM public.support_threads WHERE id = p_thread_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'thread not found' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.support_threads SET assignee_id = p_assignee_id WHERE id = p_thread_id;

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('support.assign', 'support_thread', p_thread_id::text,
          jsonb_build_object('old', v_old, 'new', p_assignee_id));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.assign_support_thread(uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.assign_support_thread(uuid, uuid) TO authenticated;
