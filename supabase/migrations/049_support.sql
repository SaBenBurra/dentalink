-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 049: Personel rolleri ve destek sohbeti
-- ═══════════════════════════════════════════════════════════════════════════════
-- staff:            personel rolleri (support, moderator, admin). Yalnızca
--                   Dashboard'dan yazılır; admin her rolü kapsar. Destek,
--                   moderasyon ve ileride admin paneli has_staff_role ile yetkilenir.
-- support_threads:  kullanıcı başına tek, sürekli destek sohbeti. Durum:
--                   open (ekip bekliyor) → answered (kullanıcı bekliyor) → resolved.
--                   Kullanıcı yazınca yeniden open olur.
-- support_messages: internal = true iç nottur, kullanıcıya görünmez.
-- Yazma yalnızca RPC ile: send_support_message (kullanıcı), reply_support ve
-- set_support_status (personel), mark_support_read (ikisi).
-- Hesap silinince sohbet cascade ile gider.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── staff ──────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'staff_role') THEN
    CREATE TYPE public.staff_role AS ENUM ('support', 'moderator', 'admin');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.staff (
  user_id     uuid              PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  role        public.staff_role NOT NULL,
  created_at  timestamptz       NOT NULL DEFAULT now()
);

ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

-- Definer: staff policy'si kendini okurken döngüye girmesin.
CREATE OR REPLACE FUNCTION public.has_staff_role(p_role public.staff_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.staff
     WHERE user_id = auth.uid()
       AND (role = p_role OR role = 'admin')
  );
$$;

REVOKE EXECUTE ON FUNCTION public.has_staff_role(public.staff_role) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.has_staff_role(public.staff_role) TO authenticated;

-- Kişi kendi rolünü görür (istemci personel menüsünü buna göre açar); destek
-- personeli atama için ekibi görür.
DROP POLICY IF EXISTS "staff_select" ON public.staff;
CREATE POLICY "staff_select" ON public.staff
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()) OR public.has_staff_role('support'));

REVOKE ALL ON public.staff FROM anon, authenticated;
GRANT SELECT ON public.staff TO authenticated;

-- ─── support_threads ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.support_threads (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid        NOT NULL UNIQUE
                                 REFERENCES public.users(id) ON DELETE CASCADE,
  status             text        NOT NULL DEFAULT 'open'
                                 CHECK (status IN ('open', 'answered', 'resolved')),
  category           text        CHECK (category IN ('bug', 'account', 'suggestion',
                                                     'complaint', 'other')),
  -- Son kullanıcı mesajındaki uygulama sürümü, platform, cihaz.
  client_info        text        CHECK (char_length(client_info) <= 200),
  assignee_id        uuid        REFERENCES public.users(id) ON DELETE SET NULL,
  last_message_at    timestamptz NOT NULL DEFAULT now(),
  user_read_at       timestamptz,
  staff_read_at      timestamptz,
  first_response_at  timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS support_threads_queue_idx
  ON public.support_threads (status, last_message_at);

ALTER TABLE public.support_threads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "support_threads_select" ON public.support_threads;
CREATE POLICY "support_threads_select" ON public.support_threads
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()) OR public.has_staff_role('support'));

REVOKE ALL ON public.support_threads FROM anon, authenticated;
GRANT SELECT ON public.support_threads TO authenticated;

-- ─── support_messages ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.support_messages (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id   uuid        NOT NULL REFERENCES public.support_threads(id) ON DELETE CASCADE,
  -- Personel hesabı silinse de cevap kalır.
  sender_id   uuid        REFERENCES public.users(id) ON DELETE SET NULL,
  from_staff  boolean     NOT NULL,
  content     text        NOT NULL CHECK (char_length(content) BETWEEN 1 AND 2000),
  internal    boolean     NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (from_staff OR NOT internal)
);

CREATE INDEX IF NOT EXISTS support_messages_thread_idx
  ON public.support_messages (thread_id, created_at);

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "support_messages_select" ON public.support_messages;
CREATE POLICY "support_messages_select" ON public.support_messages
  FOR SELECT TO authenticated
  USING (
    public.has_staff_role('support')
    OR (NOT internal AND EXISTS (
      SELECT 1 FROM public.support_threads t
       WHERE t.id = thread_id AND t.user_id = (select auth.uid())
    ))
  );

REVOKE ALL ON public.support_messages FROM anon, authenticated;
GRANT SELECT ON public.support_messages TO authenticated;

-- ─── RPC: kullanıcı yazar ───────────────────────────────────────────────────
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

  INSERT INTO public.support_threads AS t (user_id, category, client_info, user_read_at)
  VALUES (v_uid, p_category, left(p_client_info, 200), now())
  ON CONFLICT (user_id) DO UPDATE
     SET status          = 'open',
         category        = coalesce(EXCLUDED.category, t.category),
         client_info     = coalesce(EXCLUDED.client_info, t.client_info),
         last_message_at = now(),
         user_read_at    = now()
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

REVOKE EXECUTE ON FUNCTION public.send_support_message(text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.send_support_message(text, text, text) TO authenticated;

-- ─── RPC: personel cevaplar ─────────────────────────────────────────────────
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
  IF NOT public.has_staff_role('support') THEN
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
           staff_read_at     = now()
     WHERE id = p_thread_id;
  END IF;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'thread not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.support_messages (thread_id, sender_id, from_staff, content, internal)
  VALUES (p_thread_id, v_uid, true, v_content, coalesce(p_internal, false))
  RETURNING * INTO v_msg;

  RETURN v_msg;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.reply_support(uuid, text, boolean) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.reply_support(uuid, text, boolean) TO authenticated;

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
  IF NOT public.has_staff_role('support') THEN
    RAISE EXCEPTION 'not staff' USING ERRCODE = '42501';
  END IF;
  IF p_status IS NULL OR p_status NOT IN ('open', 'answered', 'resolved') THEN
    RAISE EXCEPTION 'invalid status' USING ERRCODE = '22023';
  END IF;

  UPDATE public.support_threads SET status = p_status WHERE id = p_thread_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'thread not found' USING ERRCODE = 'P0002';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_support_status(uuid, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_support_status(uuid, text) TO authenticated;

-- ─── RPC: okundu ────────────────────────────────────────────────────────────
-- Sohbetin sahibi çağırırsa user_read_at, personel çağırırsa staff_read_at.
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

  IF public.has_staff_role('support') THEN
    UPDATE public.support_threads SET staff_read_at = now() WHERE id = p_thread_id;
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.mark_support_read(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.mark_support_read(uuid) TO authenticated;

-- ─── Realtime yayını ────────────────────────────────────────────────────────
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['support_threads', 'support_messages'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;
