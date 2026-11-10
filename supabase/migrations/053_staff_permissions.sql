-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 053: Yetki modeli, işlem kaydı, gizleyen moderasyon
-- ═══════════════════════════════════════════════════════════════════════════════
-- staff_roles:    rol adı → yetki listesi; admin paneli yeni rol tanımlar.
--                 staff.role enum'dan metne geçer (değerler aynı), FK ile bağlanır.
-- has_permission: tüm yeni kontroller bunu kullanır. has_staff_role (049) aynı
--                 imzayla sarmalayıcıdır; 049 policy'leri değişmeden çalışır.
-- staff_actions:  personel işlem kaydı. 2FA olmadığı için asıl güvenlik ağı.
--                 Her personel RPC'si yazar; istemci yazamaz.
-- Moderasyon silmez, gizler: posts/comments.removed_at. Gizlenen içerik RLS'te
-- süzülür (mobil uygulama değişmez), geri alınabilir. Kim/neden staff_actions'ta.
-- reports: reports.handle yetkilisine okunur; resolve_report hedefi kapatır.
-- Son staff.manage sahibi düşürülemez (advisory lock + kontrol).
--
-- Bilinen sınırlar:
--   - Gizlenen yorum posts.comment_count'ta sayılmaya devam eder;
--     list_treatments.case_count gizli vakaları da sayar.
--   - posts.remove / comments.remove yetkilisi mobil uygulamada da gizli
--     içeriği görür (panel normal sorguyla okuyabilsin diye).
--   - users.ban, users.verify, stats.view yalnızca tanımlı; RPC'leri sonra.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── staff_roles ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.staff_roles (
  name         text        PRIMARY KEY CHECK (name ~ '^[a-z_]{2,30}$'),
  permissions  text[]      NOT NULL CHECK (permissions <@ ARRAY[
                             'support.reply', 'reports.handle', 'posts.remove',
                             'comments.remove', 'users.ban', 'users.verify',
                             'staff.manage', 'stats.view']::text[]),
  created_at   timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.staff_roles (name, permissions) VALUES
  ('support',   ARRAY['support.reply']),
  ('moderator', ARRAY['reports.handle', 'posts.remove', 'comments.remove', 'users.ban']),
  ('admin',     ARRAY['support.reply', 'reports.handle', 'posts.remove', 'comments.remove',
                      'users.ban', 'users.verify', 'staff.manage', 'stats.view'])
ON CONFLICT (name) DO NOTHING;

ALTER TABLE public.staff_roles ENABLE ROW LEVEL SECURITY;

-- ─── staff.role: enum → text + FK ───────────────────────────────────────────
-- Kullanımdaki rol silinemez (23503). staff_role enum'u has_staff_role imzası için kalır.
-- Koşullu: kolon aşağıdaki staff_roles_select policy'sinde kullanılınca tip değişmez.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_schema = 'public' AND table_name = 'staff'
                AND column_name = 'role' AND data_type <> 'text') THEN
    ALTER TABLE public.staff ALTER COLUMN role TYPE text USING role::text;
  END IF;
END $$;
ALTER TABLE public.staff DROP CONSTRAINT IF EXISTS staff_role_fkey;
ALTER TABLE public.staff ADD CONSTRAINT staff_role_fkey
  FOREIGN KEY (role) REFERENCES public.staff_roles(name) ON UPDATE CASCADE;

-- ─── has_permission ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.has_permission(p_permission text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.staff s
      JOIN public.staff_roles r ON r.name = s.role
     WHERE s.user_id = auth.uid()
       AND p_permission = ANY (r.permissions)
  );
$$;

REVOKE EXECUTE ON FUNCTION public.has_permission(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.has_permission(text) TO authenticated;

-- 049 uyumluluğu: eski rol adı → karşılık gelen yetki.
CREATE OR REPLACE FUNCTION public.has_staff_role(p_role public.staff_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT (p_role = 'support'   AND public.has_permission('support.reply'))
      OR (p_role = 'moderator' AND public.has_permission('reports.handle'))
      OR (p_role = 'admin'     AND public.has_permission('staff.manage'));
$$;

-- Kişi kendi rolünün yetkilerini görür (panel menüsü); yönetici hepsini.
DROP POLICY IF EXISTS "staff_roles_select" ON public.staff_roles;
CREATE POLICY "staff_roles_select" ON public.staff_roles
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.staff s
             WHERE s.user_id = (select auth.uid()) AND s.role = staff_roles.name)
    OR (select public.has_permission('staff.manage'))
  );

REVOKE ALL ON public.staff_roles FROM anon, authenticated;
GRANT SELECT ON public.staff_roles TO authenticated;

-- Yönetici tüm ekibi görür (049: kendisi ve destek ekibi).
DROP POLICY IF EXISTS "staff_select" ON public.staff;
CREATE POLICY "staff_select" ON public.staff
  FOR SELECT TO authenticated
  USING (
    user_id = (select auth.uid())
    OR (select public.has_permission('support.reply'))
    OR (select public.has_permission('staff.manage'))
  );

-- ─── staff_actions ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.staff_actions (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id     uuid        DEFAULT auth.uid()
                           REFERENCES public.users(id) ON DELETE SET NULL,
  action       text        NOT NULL,
  target_type  text        NOT NULL,
  -- Metin: hedef rol adı da olabilir.
  target_id    text        NOT NULL,
  reason       text        CHECK (char_length(reason) <= 500),
  detail       jsonb,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS staff_actions_created_idx
  ON public.staff_actions (created_at DESC);
CREATE INDEX IF NOT EXISTS staff_actions_target_idx
  ON public.staff_actions (target_type, target_id, created_at DESC);

ALTER TABLE public.staff_actions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "staff_actions_select" ON public.staff_actions;
CREATE POLICY "staff_actions_select" ON public.staff_actions
  FOR SELECT TO authenticated
  USING ((select public.has_permission('staff.manage')));

REVOKE ALL ON public.staff_actions FROM anon, authenticated;
GRANT SELECT ON public.staff_actions TO authenticated;

-- ─── Personel ve rol yönetimi ───────────────────────────────────────────────
-- Değişiklikten sonra çağrılır; staff.manage sahibi kalmadıysa işlem geri alınır.
CREATE OR REPLACE FUNCTION public.ensure_staff_manager()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.staff s
      JOIN public.staff_roles r ON r.name = s.role
     WHERE 'staff.manage' = ANY (r.permissions)
  ) THEN
    RAISE EXCEPTION 'last admin' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.ensure_staff_manager() FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.set_staff_role(p_user_id uuid, p_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old text;
BEGIN
  IF NOT public.has_permission('staff.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  -- İki yönetici aynı anda birbirini düşürmesin.
  PERFORM pg_advisory_xact_lock(hashtext('staff.manage'));

  SELECT role INTO v_old FROM public.staff WHERE user_id = p_user_id;

  INSERT INTO public.staff (user_id, role) VALUES (p_user_id, p_role)
  ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role;

  PERFORM public.ensure_staff_manager();

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('staff.set_role', 'user', p_user_id::text,
          jsonb_build_object('old', v_old, 'new', p_role));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_staff_role(uuid, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_staff_role(uuid, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.remove_staff(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old text;
BEGIN
  IF NOT public.has_permission('staff.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtext('staff.manage'));

  DELETE FROM public.staff WHERE user_id = p_user_id RETURNING role INTO v_old;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'staff not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM public.ensure_staff_manager();

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('staff.remove', 'user', p_user_id::text, jsonb_build_object('old', v_old));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.remove_staff(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.remove_staff(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.save_staff_role(p_name text, p_permissions text[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old text[];
BEGIN
  IF NOT public.has_permission('staff.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtext('staff.manage'));

  SELECT permissions INTO v_old FROM public.staff_roles WHERE name = p_name;

  -- Bilinmeyen yetki ya da geçersiz ad CHECK ile 23514 verir.
  INSERT INTO public.staff_roles (name, permissions)
  VALUES (p_name, coalesce(p_permissions, '{}'))
  ON CONFLICT (name) DO UPDATE SET permissions = EXCLUDED.permissions;

  PERFORM public.ensure_staff_manager();

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('role.save', 'role', p_name,
          jsonb_build_object('old', v_old, 'new', p_permissions));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.save_staff_role(text, text[]) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.save_staff_role(text, text[]) TO authenticated;

CREATE OR REPLACE FUNCTION public.delete_staff_role(p_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old text[];
BEGIN
  IF NOT public.has_permission('staff.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;

  -- Kullanımdaki rol FK ile 23503 verir.
  DELETE FROM public.staff_roles WHERE name = p_name RETURNING permissions INTO v_old;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'role not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('role.delete', 'role', p_name, jsonb_build_object('old', v_old));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_staff_role(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_staff_role(text) TO authenticated;

-- ─── Gizleyen moderasyon ────────────────────────────────────────────────────
-- Kolonlar istemciye UPDATE grant'li değil (012): sahibi geri açamaz.
ALTER TABLE public.posts    ADD COLUMN IF NOT EXISTS removed_at timestamptz;
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS removed_at timestamptz;

DROP POLICY IF EXISTS "posts_select_all" ON public.posts;
CREATE POLICY "posts_select_all" ON public.posts
  FOR SELECT TO authenticated
  USING (
    NOT public.is_blocked_between((select auth.uid()), user_id)
    AND (removed_at IS NULL OR (select public.has_permission('posts.remove')))
  );

DROP POLICY IF EXISTS "comments_select_all" ON public.comments;
CREATE POLICY "comments_select_all" ON public.comments
  FOR SELECT TO authenticated
  USING (
    NOT public.is_blocked_between((select auth.uid()), user_id)
    AND (removed_at IS NULL OR (select public.has_permission('comments.remove')))
  );

-- p_remove = false geri alır.
CREATE OR REPLACE FUNCTION public.moderate_content(
  p_target_type text,
  p_target_id   uuid,
  p_remove      boolean,
  p_reason      text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_at     timestamptz;
  v_action text := 'content.restore';
BEGIN
  IF p_remove IS NULL THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  IF p_remove THEN
    v_at := now();
    v_action := 'content.remove';
  END IF;

  IF p_target_type = 'post' THEN
    IF NOT public.has_permission('posts.remove') THEN
      RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
    END IF;
    UPDATE public.posts SET removed_at = v_at WHERE id = p_target_id;
  ELSIF p_target_type = 'comment' THEN
    IF NOT public.has_permission('comments.remove') THEN
      RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
    END IF;
    UPDATE public.comments SET removed_at = v_at WHERE id = p_target_id;
  ELSE
    RAISE EXCEPTION 'invalid target type' USING ERRCODE = '22023';
  END IF;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'target not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id, reason)
  VALUES (v_action, p_target_type, p_target_id::text, left(p_reason, 500));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.moderate_content(text, uuid, boolean, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.moderate_content(text, uuid, boolean, text) TO authenticated;

-- ─── reports ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "reports_select_staff" ON public.reports;
CREATE POLICY "reports_select_staff" ON public.reports
  FOR SELECT TO authenticated
  USING ((select public.has_permission('reports.handle')));

GRANT SELECT ON public.reports TO authenticated;

-- Hedefin tüm açık raporlarını kapatır.
CREATE OR REPLACE FUNCTION public.resolve_report(
  p_target_type text,
  p_target_id   uuid,
  p_status      text,
  p_reason      text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_n integer;
BEGIN
  IF NOT public.has_permission('reports.handle') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_status IS NULL OR p_status NOT IN ('actioned', 'dismissed') THEN
    RAISE EXCEPTION 'invalid status' USING ERRCODE = '22023';
  END IF;

  UPDATE public.reports SET status = p_status
   WHERE target_type = p_target_type AND target_id = p_target_id AND status = 'open';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  IF v_n = 0 THEN
    RAISE EXCEPTION 'no open reports' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id, reason, detail)
  VALUES ('report.' || p_status, p_target_type, p_target_id::text, left(p_reason, 500),
          jsonb_build_object('reports', v_n));
  RETURN v_n;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.resolve_report(text, uuid, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.resolve_report(text, uuid, text, text) TO authenticated;

-- ─── Destek RPC'leri: has_permission + işlem kaydı (049 imzaları aynı) ──────
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
           staff_read_at     = now()
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

  UPDATE public.support_threads SET status = p_status WHERE id = p_thread_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'thread not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('support.status', 'support_thread', p_thread_id::text,
          jsonb_build_object('status', p_status));
END;
$$;
